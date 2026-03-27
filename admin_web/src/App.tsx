import { 
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, 
  AreaChart, Area 
} from 'recharts';
import { 
  Bus, Users, Activity, Settings, 
  Map as MapIcon, ShieldAlert, Cpu, Zap
} from 'lucide-react';
import { motion } from 'framer-motion';

const activityData = [
  { time: '06:00', load: 30 },
  { time: '08:00', load: 85 },
  { time: '10:00', load: 45 },
  { time: '12:00', load: 50 },
  { time: '14:00', load: 60 },
  { time: '16:00', load: 75 },
  { time: '18:00', load: 95 },
  { time: '20:00', load: 40 },
];

const SidebarItem = ({ icon: Icon, label, active = false }: any) => (
  <motion.div 
    whileHover={{ x: 5 }}
    className={`flex items-center gap-4 p-4 rounded-xl cursor-pointer transition-all duration-300 ${
      active ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white hover:bg-white/5'
    }`}
  >
    <Icon size={20} className={active ? 'text-[#4A90E2]' : ''} />
    <span className="font-medium text-sm tracking-wide">{label}</span>
  </motion.div>
);

const StatCard = ({ title, value, sub, icon: Icon, color }: any) => (
  <motion.div 
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="glass-panel p-6 rounded-3xl"
  >
    <div className="flex justify-between items-start mb-4">
      <div className={`p-3 rounded-2xl bg-opacity-20`} style={{ backgroundColor: `${color}20` }}>
        <Icon size={24} color={color} />
      </div>
      <div className="text-right">
        <div className="text-gray-400 text-sm font-medium">{title}</div>
        <div className="text-3xl font-bold mt-1 text-white">{value}</div>
      </div>
    </div>
    <div className="text-sm" style={{ color }}>{sub}</div>
  </motion.div>
);

const FleetMap = () => (
  <div className="relative w-full h-full bg-[#111] overflow-hidden rounded-2xl border border-white/5">
    <div className="absolute inset-0 opacity-20 bg-[url('https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png')]"></div>
    <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0c] via-transparent to-transparent"></div>
    
    {/* Grid Overlay */}
    <div className="absolute inset-0 grid grid-cols-12 grid-rows-12 opacity-10 pointer-events-none">
      {[...Array(144)].map((_, i) => (
        <div key={i} className="border-[0.5px] border-white/20"></div>
      ))}
    </div>

    {/* Simulated Buses */}
    <motion.div 
      animate={{ 
        x: [40, 120, 180, 220, 180, 120, 40],
        y: [30, 60, 110, 150, 110, 60, 30] 
      }}
      transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
      className="absolute w-2 h-2 bg-[#4A90E2] rounded-full shadow-[0_0_10px_#4A90E2]"
    />
    <motion.div 
      animate={{ 
        x: [250, 180, 100, 50, 100, 180, 250],
        y: [80, 120, 180, 210, 180, 120, 80] 
      }}
      transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
      className="absolute w-2 h-2 bg-[#d44ae2] rounded-full shadow-[0_0_10px_#d44ae2]"
    />
     <motion.div 
      animate={{ 
        x: [100, 150, 200, 250, 200, 150, 100],
        y: [200, 150, 100, 50, 100, 150, 200] 
      }}
      transition={{ duration: 18, repeat: Infinity, ease: "linear" }}
      className="absolute w-2 h-2 bg-emerald-500 rounded-full shadow-[0_0_10px_#10b981]"
    />

    <div className="absolute top-4 left-4 glass p-2 rounded-lg text-[10px] font-mono text-gray-400">
      LIVE_FLEET_COORDINATES
    </div>
  </div>
);

function App() {
  return (
    <div className="flex h-screen w-full bg-[#0a0a0c] overflow-hidden p-6 gap-6 relative">
      {/* Background flare */}
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] bg-[#4A90E2] opacity-10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] bg-[#d44ae2] opacity-10 rounded-full blur-[120px] pointer-events-none" />

      {/* Sidebar */}
      <div className="w-64 flex flex-col glass-panel rounded-3xl p-6 relative z-10">
        <div className="flex items-center gap-3 mb-12">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#4A90E2] to-[#d44ae2] flex items-center justify-center">
            <Zap size={20} className="text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight text-white">VELOCITY<br/><span className="text-[#4A90E2]">TRANSIT</span></span>
        </div>
        
        <div className="flex flex-col gap-2 flex-grow">
          <SidebarItem icon={Activity} label="Live Operations" active />
          <SidebarItem icon={MapIcon} label="Fleet Map" />
          <SidebarItem icon={Cpu} label="AI Copilot" />
          <SidebarItem icon={Users} label="Load Balancing" />
          <SidebarItem icon={Bus} label="Drivers & Vehicles" />
        </div>

        <div className="mt-auto">
          <SidebarItem icon={Settings} label="System Settings" />
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col gap-6 relative z-10">
        <header className="flex justify-between items-center glass-panel px-8 py-4 rounded-3xl">
          <div>
            <h1 className="text-2xl font-bold text-white tracking-tight">System Overview</h1>
            <p className="text-gray-400 text-sm mt-1">Real-time scheduling and route management intelligence</p>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <span className="relative flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
              </span>
              <span className="text-sm font-medium text-gray-300">System Online (AI Active)</span>
            </div>
            <div className="h-10 w-10 rounded-full bg-gray-800 border-2 border-[#4A90E2] overflow-hidden" />
          </div>
        </header>

        {/* Stats Grid */}
        <div className="grid grid-cols-4 gap-6">
          <StatCard title="Active Fleet" value="142" sub="8 buses entering service" icon={Bus} color="#4A90E2" />
          <StatCard title="Total Passengers" value="12.4k" sub="+14% from last hour" icon={Users} color="#10b981" />
          <StatCard title="Efficiency Score" value="98.2%" sub="AI optimized scheduling" icon={Activity} color="#8b5cf6" />
          <StatCard title="Active Alerts" value="3" sub="2 minor delays, 1 detour" icon={ShieldAlert} color="#ef4444" />
        </div>

        {/* Main Dashboard Area */}
        <div className="flex-1 grid grid-cols-3 gap-6">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="col-span-2 glass-panel rounded-3xl p-6 flex flex-col h-[400px]"
          >
            <div className="flex-1 grid grid-cols-2 gap-6 min-h-0">
               <div className="flex flex-col">
                  <div className="flex justify-between items-center mb-6">
                    <h2 className="text-lg font-semibold text-white">Predictive Load</h2>
                    <div className="px-3 py-1 rounded-full bg-[#4A90E2]/20 text-[#4A90E2] text-[10px] font-bold font-mono">
                      AI_PREDICT
                    </div>
                  </div>
                  <div className="flex-1 min-h-0 relative">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={activityData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                        <defs>
                          <linearGradient id="colorLoad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#4A90E2" stopOpacity={0.8}/>
                            <stop offset="95%" stopColor="#4A90E2" stopOpacity={0}/>
                          </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#2A2A2A" vertical={false} />
                        <XAxis dataKey="time" stroke="#666" tick={{fill: '#888', fontSize: 10}} tickLine={false} axisLine={false} />
                        <YAxis stroke="#666" tick={{fill: '#888', fontSize: 10}} tickLine={false} axisLine={false} />
                        <Tooltip 
                          contentStyle={{ backgroundColor: 'rgba(10,10,12,0.9)', border: '1px solid #333', borderRadius: '12px' }}
                          itemStyle={{ color: '#fff' }}
                        />
                        <Area type="monotone" dataKey="load" stroke="#4A90E2" strokeWidth={2} fillOpacity={1} fill="url(#colorLoad)" />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
               </div>
               <div className="flex flex-col">
                  <div className="flex justify-between items-center mb-6">
                    <h2 className="text-lg font-semibold text-white">Live Fleet Tracking</h2>
                    <div className="px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-500 text-[10px] font-bold font-mono">
                      MAP_v4.2
                    </div>
                  </div>
                  <div className="flex-1 min-h-0">
                    <FleetMap />
                  </div>
               </div>
            </div>
          </motion.div>

          {/* Right Column: Live Feed */}
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="glass-panel rounded-3xl p-6 flex flex-col"
          >
            <h2 className="text-lg font-semibold text-white mb-6">Live AI Event Log</h2>
            <div className="flex-1 overflow-y-auto pr-2 space-y-4">
              {[
                { time: 'Just now', msg: 'Re-routing Bus 402 to avoid heavy traffic on Route 1', type: 'alert' },
                { time: '2m ago', msg: 'Deployed 2 additional buses to Route 5 (High demand predicted)', type: 'system' },
                { time: '8m ago', msg: 'Driver matching algorithm completed for next shift', type: 'system' },
                { time: '12m ago', msg: 'Speed optimized across network. Network efficiency +3%', type: 'success' },
                { time: '15m ago', msg: 'Bus 108 battery critically low. Sending return signal.', type: 'alert' },
              ].map((log, i) => (
                <div key={i} className="flex gap-4 p-3 rounded-2xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                  <div className={`mt-0.5 w-2 h-2 rounded-full flex-shrink-0 ${
                    log.type === 'alert' ? 'bg-red-500 shadow-[0_0_10px_rgba(239,68,68,0.5)]' : 
                    log.type === 'success' ? 'bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]' : 
                    'bg-[#4A90E2] shadow-[0_0_10px_rgba(74,144,226,0.5)]'
                  }`} />
                  <div>
                    <div className="text-xs text-gray-400 mb-0.5">{log.time}</div>
                    <div className="text-sm font-medium text-gray-200 leading-snug">{log.msg}</div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}

export default App;
