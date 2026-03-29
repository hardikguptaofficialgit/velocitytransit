const { getDemoRoutes, getDemoBuses } = require('./demoTransit');

function toSeedRouteId(demoRouteId) {
  return demoRouteId.replace(/^demo_route_/, 'seed_route_');
}

function toSeedBusId(routeId, index) {
  const suffix = routeId.replace(/^seed_route_/, '').toUpperCase();
  return `seed_bus_${suffix}_${index + 1}`;
}

function toSeedAssignmentId(busId) {
  return `assignment_${busId}`;
}

function interpolate(from, to, t) {
  return {
    lat: from.lat + (to.lat - from.lat) * t,
    lng: from.lng + (to.lng - from.lng) * t,
  };
}

function heading(from, to) {
  const deltaLat = to.lat - from.lat;
  const deltaLng = to.lng - from.lng;
  return (Math.atan2(deltaLng, deltaLat) * 180) / Math.PI;
}

function positionOnPath(pathPoints, progress) {
  if (!pathPoints.length) {
    return { lat: 0, lng: 0, heading: 0 };
  }

  if (pathPoints.length === 1) {
    return { ...pathPoints[0], heading: 0 };
  }

  const scaledIndex = progress * (pathPoints.length - 1);
  const index = Math.min(pathPoints.length - 2, Math.max(0, Math.floor(scaledIndex)));
  const t = scaledIndex - index;
  const from = pathPoints[index];
  const to = pathPoints[index + 1];

  return {
    ...interpolate(from, to, t),
    heading: heading(from, to),
  };
}

function progressForBus(seedIndex, timestampMs = Date.now()) {
  const loopMs = 14 * 60 * 1000;
  const offset = (seedIndex * 97_123) % loopMs;
  return ((timestampMs + offset) % loopMs) / loopMs;
}

function buildSeedRoutes() {
  return getDemoRoutes().map((route) => ({
    id: toSeedRouteId(route.id),
    name: route.name,
    shortName: `${route.shortName}R`,
    colorIndex: route.colorIndex,
    stops: route.stops.map((stop, index) => ({
      id: `${toSeedRouteId(route.id)}_stop_${index + 1}`,
      name: stop.name,
      lat: stop.position.lat,
      lng: stop.position.lng,
      isActive: true,
    })),
    pathPoints: route.pathPoints.map((point) => ({
      lat: point.lat,
      lng: point.lng,
    })),
    isActive: true,
    source: 'seeded',
    seeded: true,
  }));
}

function buildSeedBuses(routes) {
  const demoBuses = getDemoBuses();
  const routeById = new Map(routes.map((route) => [route.id.replace(/^seed_/, 'demo_'), route]));
  const groupedByDemoRoute = new Map();

  demoBuses.forEach((bus) => {
    const group = groupedByDemoRoute.get(bus.routeId) || [];
    group.push(bus);
    groupedByDemoRoute.set(bus.routeId, group);
  });

  return Array.from(groupedByDemoRoute.entries()).flatMap(([demoRouteId, buses]) => {
    const seedRouteId = toSeedRouteId(demoRouteId);
    const route = routeById.get(demoRouteId);
    return buses.slice(0, 2).map((bus, index) => ({
      id: toSeedBusId(seedRouteId, index),
      busNumber: `${route ? route.shortName : bus.routeShortName || 'R'}-${301 + index + buses.length * index}`,
      routeId: seedRouteId,
      capacity: bus.capacity,
      status: 'active',
      source: 'seeded',
      seeded: true,
      driverName: bus.driverName,
    }));
  });
}

function buildSeedAssignments(buses) {
  return buses.map((bus, index) => ({
    id: toSeedAssignmentId(bus.id),
    busId: bus.id,
    driverId: `seed_driver_${index + 1}`,
    driverName: bus.driverName || `Seed Driver ${index + 1}`,
    busNumber: bus.busNumber,
    routeId: bus.routeId,
    assignedBy: 'seed_script',
    isActive: true,
    startedAt: new Date(Date.now() - (index + 1) * 600000).toISOString(),
    endedAt: null,
    source: 'seeded',
    seeded: true,
  }));
}

function createSeedFleetSnapshot(timestampMs = Date.now()) {
  const routes = buildSeedRoutes();
  const buses = buildSeedBuses(routes);
  const assignments = buildSeedAssignments(buses);
  const routeMap = new Map(routes.map((route) => [route.id, route]));

  const liveLocations = buses.map((bus, index) => {
    const route = routeMap.get(bus.routeId);
    const progress = progressForBus(index + 1, timestampMs);
    const position = positionOnPath(route ? route.pathPoints : [], progress);
    const speed = 22 + ((index * 9) % 18);

    return {
      busId: bus.id,
      busNumber: bus.busNumber,
      driverId: assignments[index].driverId,
      driverName: assignments[index].driverName,
      routeId: bus.routeId,
      isOnline: true,
      lat: position.lat,
      lng: position.lng,
      speed,
      heading: position.heading,
      lastUpdated: new Date(timestampMs).toISOString(),
      source: 'seeded',
      seeded: true,
    };
  });

  return { routes, buses, assignments, liveLocations };
}

async function seedFleetData(db) {
  const { routes, buses, assignments, liveLocations } = createSeedFleetSnapshot();
  const batch = db.batch();

  routes.forEach((route) => {
    batch.set(
      db.collection('routes').doc(route.id),
      {
        name: route.name,
        shortName: route.shortName,
        colorIndex: route.colorIndex,
        stops: route.stops,
        pathPoints: route.pathPoints,
        isActive: true,
        source: 'seeded',
        seeded: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
  });

  buses.forEach((bus) => {
    batch.set(
      db.collection('buses').doc(bus.id),
      {
        busNumber: bus.busNumber,
        routeId: bus.routeId,
        capacity: bus.capacity,
        status: bus.status,
        source: 'seeded',
        seeded: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
  });

  assignments.forEach((assignment) => {
    batch.set(
      db.collection('assignments').doc(assignment.id),
      assignment,
      { merge: true },
    );
  });

  liveLocations.forEach((liveLocation) => {
    batch.set(
      db.collection('liveLocations').doc(liveLocation.busId),
      liveLocation,
      { merge: true },
    );
  });

  await batch.commit();
  return { routes: routes.length, buses: buses.length, assignments: assignments.length };
}

async function syncSeedFleetLiveLocations(db, io) {
  const routeSnapshot = await db.collection('routes').where('seeded', '==', true).where('isActive', '==', true).get();
  const busSnapshot = await db.collection('buses').where('seeded', '==', true).get();
  const assignmentSnapshot = await db.collection('assignments').where('seeded', '==', true).where('isActive', '==', true).get();

  const routes = routeSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const buses = busSnapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((bus) => bus.status !== 'inactive');
  const assignments = assignmentSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  if (!routes.length || !buses.length) {
    return { updated: 0 };
  }

  const liveLocations = buildSeedLiveLocations({ routes, buses, assignments });
  const batch = db.batch();

  liveLocations.forEach((liveLocation) => {
    batch.set(db.collection('liveLocations').doc(liveLocation.busId), liveLocation, { merge: true });
  });

  await batch.commit();

  if (io) {
    liveLocations.forEach((liveLocation) => {
      io.to('passengers').emit('bus:position', liveLocation);
      io.to('admins').emit('fleet:update', liveLocation);
    });
  }

  return { updated: liveLocations.length };
}

function buildSeedLiveLocations({ routes, buses, assignments, timestampMs = Date.now() }) {
  const routeMap = new Map(routes.map((route) => [route.id, route]));
  const assignmentByBusId = new Map(assignments.map((assignment) => [assignment.busId, assignment]));
  return buses.map((bus, index) => {
    const route = routeMap.get(bus.routeId);
    const progress = progressForBus(index + 1, timestampMs);
    const position = positionOnPath(route ? route.pathPoints || [] : [], progress);
    const speed = 24 + ((index * 7) % 16);
    const assignment = assignmentByBusId.get(bus.id);

    return {
      busId: bus.id,
      busNumber: bus.busNumber,
      driverId: assignment?.driverId || `seed_driver_${index + 1}`,
      driverName: assignment?.driverName || `Seed Driver ${index + 1}`,
      routeId: bus.routeId,
      isOnline: true,
      lat: position.lat,
      lng: position.lng,
      speed,
      heading: position.heading,
      lastUpdated: new Date(timestampMs).toISOString(),
      source: 'seeded',
      seeded: true,
    };
  });
}

async function getSeedFleetLivePositions(db) {
  const [routeSnapshot, busSnapshot, assignmentSnapshot] = await Promise.all([
    db.collection('routes').where('seeded', '==', true).where('isActive', '==', true).get(),
    db.collection('buses').where('seeded', '==', true).get(),
    db.collection('assignments').where('seeded', '==', true).where('isActive', '==', true).get(),
  ]);

  const routes = routeSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const buses = busSnapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((bus) => bus.status !== 'inactive');
  const assignments = assignmentSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  if (!routes.length || !buses.length) {
    return [];
  }

  return buildSeedLiveLocations({ routes, buses, assignments });
}

function startSeedFleetSimulator({ db, io, intervalMs = 8000 } = {}) {
  const enabled = process.env.ENABLE_SEED_FLEET_SIMULATOR !== 'false';
  if (!enabled) {
    return { stop() {} };
  }

  let timer = null;

  const run = async () => {
    try {
      await seedFleetData(db);
      await syncSeedFleetLiveLocations(db, io);
    } catch (error) {
      console.error('[SeedFleetSimulator] sync failed:', error.message);
    }
  };

  void run();
  timer = setInterval(run, intervalMs);

  return {
    stop() {
      if (timer) {
        clearInterval(timer);
        timer = null;
      }
    },
  };
}

module.exports = {
  buildSeedLiveLocations,
  createSeedFleetSnapshot,
  getSeedFleetLivePositions,
  seedFleetData,
  startSeedFleetSimulator,
  syncSeedFleetLiveLocations,
};
