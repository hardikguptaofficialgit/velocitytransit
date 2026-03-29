const DEMO_CENTER = { lat: 20.2961, lng: 85.8245 };

const routeTemplates = [
  {
    id: 'demo_route_g1',
    shortName: 'G1',
    name: 'Grand Avenue Express',
    colorIndex: 0,
    stops: [
      ['West Terminal', 0.0, 0.0],
      ['Central Square', 0.005, 0.003],
      ['Plaza West', 0.01, 0.007],
      ['Main Hub', 0.014, 0.012],
      ['Bridge Street', 0.018, 0.016],
      ['North Point', 0.025, 0.018],
      ['East Terminal', 0.035, 0.015],
    ],
  },
  {
    id: 'demo_route_t2',
    shortName: 'T2',
    name: 'Tech Park Shuttle',
    colorIndex: 1,
    stops: [
      ['Tech Hub Central', 0.02, -0.01],
      ['Innovation Park', 0.025, -0.005],
      ['Startup Alley', 0.03, 0.0],
      ['Data Center', 0.032, 0.008],
      ['Cloud Campus', 0.028, 0.015],
      ['Tech Park East', 0.022, 0.022],
    ],
  },
  {
    id: 'demo_route_a3',
    shortName: 'A3',
    name: 'Airport Link',
    colorIndex: 2,
    stops: [
      ['Terminal 1', 0.05, 0.03],
      ['Cargo Area', 0.042, 0.025],
      ['Airport Metro', 0.035, 0.02],
      ['Highway Junction', 0.025, 0.015],
      ['City Center', 0.01, 0.005],
      ['South Terminal', -0.005, 0.0],
    ],
  },
  {
    id: 'demo_route_u4',
    shortName: 'U4',
    name: 'University Loop',
    colorIndex: 3,
    stops: [
      ['University Gate', -0.01, 0.01],
      ['Library Point', -0.005, 0.015],
      ['Sports Complex', 0.0, 0.02],
      ['Hostel Area', 0.005, 0.015],
      ['Research Block', 0.005, 0.01],
      ['Main Gate', -0.01, 0.01],
    ],
  },
  {
    id: 'demo_route_c5',
    shortName: 'C5',
    name: 'Central Business District',
    colorIndex: 4,
    stops: [
      ['CBD North', 0.008, -0.005],
      ['Financial Tower', 0.012, 0.0],
      ['Stock Exchange', 0.015, 0.005],
      ['Trade Center', 0.012, 0.012],
      ['Business Bay', 0.008, 0.018],
      ['CBD South', 0.003, 0.015],
    ],
  },
];

const driverNames = [
  'Amit',
  'Neha',
  'Rohan',
  'Priya',
  'Sanjay',
  'Kiran',
  'Meera',
  'Arjun',
  'Vikram',
  'Isha',
  'Kabir',
  'Naina',
  'Rahul',
  'Pooja',
  'Dev',
];

function point(latOffset, lngOffset) {
  return {
    lat: DEMO_CENTER.lat + latOffset,
    lng: DEMO_CENTER.lng + lngOffset,
  };
}

function interpolate(from, to, t) {
  return {
    lat: from.lat + (to.lat - from.lat) * t,
    lng: from.lng + (to.lng - from.lng) * t,
  };
}

function buildPathPoints(stops) {
  if (stops.length < 2) {
    return stops.map((stop) => stop.position);
  }

  const pathPoints = [];
  for (let index = 0; index < stops.length - 1; index += 1) {
    const from = stops[index].position;
    const to = stops[index + 1].position;
    for (let t = 0; t < 1; t += 0.1) {
      pathPoints.push(interpolate(from, to, t));
    }
  }
  pathPoints.push(stops[stops.length - 1].position);
  return pathPoints;
}

function heading(from, to) {
  const deltaLat = to.lat - from.lat;
  const deltaLng = to.lng - from.lng;
  return (Math.atan2(deltaLng, deltaLat) * 180) / Math.PI;
}

function getProgress(seed, timestampMs = Date.now()) {
  const loopMs = 12 * 60 * 1000;
  const offset = (seed * 911) % loopMs;
  return ((timestampMs + offset) % loopMs) / loopMs;
}

function positionOnPath(pathPoints, progress) {
  if (!pathPoints.length) {
    return { lat: DEMO_CENTER.lat, lng: DEMO_CENTER.lng, heading: 0 };
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

const demoRoutes = routeTemplates.map((route) => {
  const stops = route.stops.map(([name, latOffset, lngOffset], index) => ({
    id: `${route.id}_stop_${index + 1}`,
    name,
    position: point(latOffset, lngOffset),
  }));

  return {
    id: route.id,
    shortName: route.shortName,
    name: route.name,
    colorIndex: route.colorIndex,
    stops,
    pathPoints: buildPathPoints(stops),
    isActive: true,
    isDemo: true,
    readOnly: true,
    source: 'demo',
  };
});

const demoBuses = demoRoutes.flatMap((route, routeIndex) => {
  return Array.from({ length: 3 }, (_, busIndex) => {
    const number = `${route.shortName}-${210 + routeIndex * 12 + busIndex}`;
    const driverName = driverNames[(routeIndex * 3 + busIndex) % driverNames.length];
    return {
      id: `${route.id}_bus_${busIndex + 1}`,
      busNumber: number,
      routeId: route.id,
      routeName: route.name,
      routeShortName: route.shortName,
      capacity: 40 + ((routeIndex + busIndex) % 3) * 4,
      status: busIndex === 2 && routeIndex % 2 === 1 ? 'boarding' : 'active',
      source: 'demo',
      isDemo: true,
      readOnly: true,
      driverId: `demo_driver_${routeIndex}_${busIndex}`,
      driverName,
      createdAt: 'demo',
    };
  });
});

function getDemoRoutes() {
  return demoRoutes.map((route) => ({ ...route }));
}

function getDemoBuses() {
  return demoBuses.map((bus) => ({ ...bus }));
}

function getDemoLivePositions(timestampMs = Date.now()) {
  return demoBuses.map((bus, index) => {
    const route = demoRoutes.find((item) => item.id === bus.routeId);
    const progress = getProgress(index + 1, timestampMs);
    const position = positionOnPath(route ? route.pathPoints : [], progress);
    const speed = bus.status === 'boarding' ? 8 : 22 + ((index * 7) % 14);

    return {
      id: bus.id,
      busId: bus.id,
      busNumber: bus.busNumber,
      driverId: bus.driverId,
      driverName: bus.driverName,
      routeId: bus.routeId,
      routeName: bus.routeName,
      routeShortName: bus.routeShortName,
      isOnline: true,
      lat: position.lat,
      lng: position.lng,
      speed,
      heading: position.heading,
      status: bus.status,
      source: 'demo',
      isDemo: true,
      lastUpdated: new Date(timestampMs).toISOString(),
    };
  });
}

function getDemoAssignments(timestampMs = Date.now()) {
  return demoBuses.map((bus, index) => ({
    id: `demo_assignment_${index + 1}`,
    busId: bus.id,
    driverId: bus.driverId,
    busNumber: bus.busNumber,
    driverName: bus.driverName,
    routeId: bus.routeId,
    routeName: bus.routeName,
    source: 'demo',
    isDemo: true,
    readOnly: true,
    isActive: true,
    startedAt: new Date(timestampMs - (index + 1) * 15 * 60 * 1000).toISOString(),
    endedAt: null,
  }));
}

function mergeRecords(primary = [], secondary = [], idField = 'id') {
  const map = new Map();
  secondary.forEach((item) => {
    map.set(item[idField], item);
  });
  primary.forEach((item) => {
    map.set(item[idField], item);
  });
  return Array.from(map.values());
}

module.exports = {
  getDemoAssignments,
  getDemoBuses,
  getDemoLivePositions,
  getDemoRoutes,
  mergeRecords,
};
