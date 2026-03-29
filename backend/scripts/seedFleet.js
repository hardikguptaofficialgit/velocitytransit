require('dotenv').config();
require('../config/firebase');

const { db } = require('../config/firebase');
const { seedFleetData, syncSeedFleetLiveLocations } = require('../services/seedFleetSimulator');

async function main() {
  const summary = await seedFleetData(db);
  const live = await syncSeedFleetLiveLocations(db);
  console.log(`[SeedFleet] Seeded ${summary.routes} routes, ${summary.buses} buses, ${summary.assignments} assignments.`);
  console.log(`[SeedFleet] Updated ${live.updated} live bus positions.`);
  process.exit(0);
}

main().catch((error) => {
  console.error('[SeedFleet] Failed:', error);
  process.exit(1);
});
