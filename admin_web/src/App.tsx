import { useState, useEffect, useCallback } from 'react';
import { auth, googleProvider } from './config/firebase';
import type { User } from 'firebase/auth';
import {
  signInWithEmailAndPassword,
  signInWithPopup,
  onAuthStateChanged,
  signOut,
} from 'firebase/auth';
import { apiFetch } from './lib/api';
import { io } from 'socket.io-client';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Bus, Users, MapPin, LogOut, Plus, Trash2, Shield,
  Activity, Radio, UserCheck, AlertCircle, ChevronRight,
  Clock, Gauge, Navigation, Zap,
} from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000';

// ═══════════════ Types ═══════════════
interface UserProfile {
  uid: string; email: string; name: string; role: string;
  phone?: string; isActive?: boolean;
}
interface BusData {
  id: string; busNumber: string; routeId?: string;
  capacity: number; status: string;
}
interface Assignment {
  id: string; busId: string; driverId: string;
  busNumber: string; driverName: string;
  routeId?: string; isActive: boolean; startedAt: string;
}
interface LivePosition {
  busId: string; busNumber: string; lat: number; lng: number;
  speed: number; heading: number; driverId: string; lastUpdated: string;
}

// ═══════════════ Stagger animation helpers ═══════════════
const container = { hidden: {}, show: { transition: { staggerChildren: 0.06 } } };
const item = { hidden: { opacity: 0, y: 12 }, show: { opacity: 1, y: 0, transition: { duration: 0.35 } } };

// ═══════════════ Login Page ═══════════════
function LoginPage({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleEmail = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setError('');
    try {
      await signInWithEmailAndPassword(auth, email, password);
      onLogin();
    } catch (err: any) {
      setError(err.message?.includes('invalid') ? 'Invalid credentials' : err.message);
    }
    setLoading(false);
  };

  const handleGoogle = async () => {
    setLoading(true); setError('');
    try {
      await signInWithPopup(auth, googleProvider);
      onLogin();
    } catch (err: any) {
      setError(err.message);
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4" style={{ background: 'var(--bg-primary)' }}>
      <div className="mesh-bg" />

      <motion.div
        initial={{ opacity: 0, y: 30, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.5, ease: [0.4, 0, 0.2, 1] }}
        className="w-full max-w-md relative z-10"
      >
        {/* Logo */}
        <div className="text-center mb-10">
          <motion.div
            initial={{ scale: 0 }} animate={{ scale: 1 }}
            transition={{ delay: 0.1, type: 'spring', stiffness: 200 }}
            className="inline-flex items-center gap-4 mb-4"
          >
            <div className="w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg"
              style={{ background: 'var(--accent-gradient)', boxShadow: '0 8px 32px rgba(16,185,129,0.25)' }}>
              <Bus className="w-7 h-7 text-white" />
            </div>
            <h1 className="text-4xl font-black tracking-tight" style={{ color: 'var(--text-primary)' }}>
              Velocity
            </h1>
          </motion.div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9375rem' }}>
            Fleet Management Console
          </p>
        </div>

        {/* Card */}
        <div className="login-glow">
          <div className="glass-card" style={{ padding: '2rem', borderRadius: '24px' }}>
            {error && (
              <motion.div
                initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }}
                style={{
                  marginBottom: '1.25rem', padding: '0.75rem 1rem',
                  background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.15)',
                  borderRadius: '12px', color: '#f87171', fontSize: '0.8125rem',
                  display: 'flex', alignItems: 'center', gap: '0.5rem',
                }}
              >
                <AlertCircle className="w-4 h-4 flex-shrink-0" /> {error}
              </motion.div>
            )}

            <form onSubmit={handleEmail} style={{ display: 'flex', flexDirection: 'column', gap: '0.875rem', marginBottom: '1.5rem' }}>
              <input type="email" placeholder="Email address" value={email}
                onChange={e => setEmail(e.target.value)} required className="input-field" />
              <input type="password" placeholder="Password" value={password}
                onChange={e => setPassword(e.target.value)} required className="input-field" />
              <button type="submit" disabled={loading} className="btn-primary"
                style={{ width: '100%', justifyContent: 'center', padding: '0.75rem 1.25rem', borderRadius: '12px', fontSize: '0.9375rem' }}>
                {loading ? (
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Signing in...
                  </span>
                ) : 'Sign In'}
              </button>
            </form>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
              <div style={{ flex: 1, height: '1px', background: 'var(--glass-border)' }} />
              <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>or</span>
              <div style={{ flex: 1, height: '1px', background: 'var(--glass-border)' }} />
            </div>

            <button onClick={handleGoogle} disabled={loading}
              className="input-field"
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem',
                cursor: 'pointer', fontWeight: 500, padding: '0.75rem', borderRadius: '12px',
                transition: 'all 0.25s ease',
              }}
              onMouseEnter={e => { (e.target as HTMLElement).style.borderColor = 'rgba(148,163,184,0.3)'; }}
              onMouseLeave={e => { (e.target as HTMLElement).style.borderColor = 'rgba(148,163,184,0.1)'; }}
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
              Sign in with Google
            </button>
          </div>
        </div>

        <p style={{ textAlign: 'center', marginTop: '2rem', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          Velocity Transit · Real-time fleet intelligence
        </p>
      </motion.div>
    </div>
  );
}

// ═══════════════ Dashboard ═══════════════
function Dashboard() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [tab, setTab] = useState<'overview' | 'buses' | 'drivers' | 'assignments'>('overview');
  const [token, setToken] = useState('');

  // Data states
  const [buses, setBuses] = useState<BusData[]>([]);
  const [drivers, setDrivers] = useState<UserProfile[]>([]);
  const [allUsers, setAllUsers] = useState<UserProfile[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [livePositions, setLivePositions] = useState<LivePosition[]>([]);

  // Forms
  const [newBusNumber, setNewBusNumber] = useState('');
  const [newBusCapacity, setNewBusCapacity] = useState(40);
  const [assignBusId, setAssignBusId] = useState('');
  const [assignDriverId, setAssignDriverId] = useState('');

  // ── Fetch profile on mount ──
  useEffect(() => {
    if (!user || !token) return;
    apiFetch('/api/auth/me?source=admin_web', token)
      .then(data => setProfile(data.user))
      .catch(console.error);
  }, [user, token]);

  // ── Socket.io connection (connects AFTER profile is loaded, so role is correct) ──
  useEffect(() => {
    if (!token || !profile) return;
    const s = io(API_URL, { auth: { token } });
    s.on('connect', () => console.log('Socket connected'));
    s.on('bus:position', (pos: LivePosition) => {
      setLivePositions(prev => {
        const idx = prev.findIndex(p => p.busId === pos.busId);
        if (idx >= 0) { const next = [...prev]; next[idx] = pos; return next; }
        return [...prev, pos];
      });
    });
    s.on('bus:offline', ({ busId }: { busId: string }) => {
      setLivePositions(prev => prev.filter(p => p.busId !== busId));
    });
    s.emit('get:live');
    s.on('live:positions', (positions: LivePosition[]) => setLivePositions(positions));
    return () => { s.disconnect(); };
  }, [token, profile]);

  // ── Fetch data ──
  const fetchAll = useCallback(async () => {
    if (!token) return;
    try {
      const [busRes, userRes, assignRes] = await Promise.all([
        apiFetch('/api/buses', token),
        apiFetch('/api/users', token),
        apiFetch('/api/assignments?active=true', token),
      ]);
      setBuses(busRes.buses || []);
      setAllUsers(userRes.users || []);
      setDrivers((userRes.users || []).filter((u: UserProfile) => u.role === 'driver'));
      setAssignments(assignRes.assignments || []);
    } catch (err) {
      console.error('Fetch error:', err);
    }
  }, [token]);

  useEffect(() => { if (token) fetchAll(); }, [token, fetchAll]);

  // ── Auth listener ──
  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const t = await u.getIdToken();
        setToken(t);
      }
    });
  }, []);

  // ── Actions ──
  const addBus = async () => {
    if (!newBusNumber.trim()) return;
    await apiFetch('/api/buses', token, {
      method: 'POST',
      body: JSON.stringify({ busNumber: newBusNumber, capacity: newBusCapacity }),
    });
    setNewBusNumber(''); setNewBusCapacity(40);
    fetchAll();
  };

  const deleteBus = async (id: string) => {
    await apiFetch(`/api/buses/${id}`, token, { method: 'DELETE' });
    fetchAll();
  };

  const promoteToDriver = async (uid: string) => {
    await apiFetch(`/api/users/${uid}/role`, token, {
      method: 'PATCH', body: JSON.stringify({ role: 'driver' }),
    });
    fetchAll();
  };

  const demoteToPassenger = async (uid: string) => {
    await apiFetch(`/api/users/${uid}/role`, token, {
      method: 'PATCH', body: JSON.stringify({ role: 'passenger' }),
    });
    fetchAll();
  };

  const assignBus = async () => {
    if (!assignBusId || !assignDriverId) return;
    const bus = buses.find(b => b.id === assignBusId);
    const driver = drivers.find(d => d.uid === assignDriverId);
    await apiFetch('/api/assignments', token, {
      method: 'POST',
      body: JSON.stringify({
        busId: assignBusId,
        driverId: assignDriverId,
        busNumber: bus?.busNumber || '',
        driverName: driver?.name || '',
      }),
    });
    setAssignBusId(''); setAssignDriverId('');
    fetchAll();
  };

  const deactivateAssignment = async (id: string) => {
    await apiFetch(`/api/assignments/${id}/deactivate`, token, { method: 'PATCH' });
    fetchAll();
  };

  if (!profile) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-primary)' }}>
        <div className="loader" />
      </div>
    );
  }

  const tabs = [
    { id: 'overview' as const, label: 'Overview', icon: Activity },
    { id: 'buses' as const, label: 'Buses', icon: Bus },
    { id: 'drivers' as const, label: 'Drivers', icon: Users },
    { id: 'assignments' as const, label: 'Assignments', icon: Radio },
  ];

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-primary)' }}>
      <div className="mesh-bg" />

      {/* ── Sidebar ── */}
      <aside className="sidebar">
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2.5rem' }}>
          <div style={{
            width: '42px', height: '42px', borderRadius: '14px',
            background: 'var(--accent-gradient)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 16px rgba(16,185,129,0.2)',
          }}>
            <Bus className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
              Velocity
            </h1>
            <p style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', fontWeight: 500, letterSpacing: '0.02em' }}>
              ADMIN PANEL
            </p>
          </div>
        </div>

        {/* Navigation */}
        <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
          {tabs.map(t => (
            <button key={t.id} onClick={() => setTab(t.id)}
              className={`nav-item ${tab === t.id ? 'active' : ''}`}>
              <t.icon style={{ width: '18px', height: '18px' }} />
              {t.label}
              {t.id === 'assignments' && assignments.length > 0 && (
                <span className="badge" style={{
                  marginLeft: 'auto',
                  background: 'rgba(16,185,129,0.12)',
                  color: '#34d399',
                }}>
                  {assignments.length}
                </span>
              )}
              {t.id === 'overview' && livePositions.length > 0 && (
                <span style={{ marginLeft: 'auto' }}><span className="live-dot" /></span>
              )}
            </button>
          ))}
        </nav>

        {/* User footer */}
        <div style={{ borderTop: '1px solid var(--glass-border)', paddingTop: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
            <div style={{
              width: '36px', height: '36px', borderRadius: '10px',
              background: 'linear-gradient(135deg, #8b5cf6, #a855f7)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: '0.8125rem', fontWeight: 700, color: 'white',
            }}>
              {profile.name?.charAt(0)?.toUpperCase()}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: '0.875rem', fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', color: 'var(--text-primary)' }}>
                {profile.name}
              </p>
              <p style={{ fontSize: '0.6875rem', color: '#34d399', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
                <Shield style={{ width: '10px', height: '10px' }} /> Admin
              </p>
            </div>
          </div>
          <button onClick={() => signOut(auth)}
            style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: '0.5rem',
              padding: '0.5rem 0.75rem', fontSize: '0.8125rem', color: 'var(--text-muted)',
              background: 'none', border: '1px solid transparent', borderRadius: '8px',
              cursor: 'pointer', transition: 'all 0.25s ease',
            }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLElement).style.color = '#f87171';
              (e.currentTarget as HTMLElement).style.background = 'rgba(239,68,68,0.06)';
              (e.currentTarget as HTMLElement).style.borderColor = 'rgba(239,68,68,0.1)';
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLElement).style.color = 'var(--text-muted)';
              (e.currentTarget as HTMLElement).style.background = 'none';
              (e.currentTarget as HTMLElement).style.borderColor = 'transparent';
            }}
          >
            <LogOut style={{ width: '14px', height: '14px' }} /> Sign Out
          </button>
        </div>
      </aside>

      {/* ── Main Content ── */}
      <main style={{ marginLeft: 'var(--sidebar-width)', padding: '2rem 2.5rem', position: 'relative', zIndex: 1 }}>
        <AnimatePresence mode="wait">

          {/* ════════ OVERVIEW ════════ */}
          {tab === 'overview' && (
            <motion.div key="overview" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3 }}>
              <h2 className="page-title">Fleet Overview</h2>

              {/* Stats Grid */}
              <motion.div variants={container} initial="hidden" animate="show"
                style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '2rem' }}>
                {[
                  { label: 'Total Buses', value: buses.length, icon: Bus, gradient: 'linear-gradient(135deg, #3b82f6, #06b6d4)', shadow: 'rgba(59,130,246,0.2)' },
                  { label: 'Active Drivers', value: drivers.length, icon: UserCheck, gradient: 'linear-gradient(135deg, #10b981, #34d399)', shadow: 'rgba(16,185,129,0.2)' },
                  { label: 'Live Tracking', value: livePositions.length, icon: Radio, gradient: 'linear-gradient(135deg, #f59e0b, #ef4444)', shadow: 'rgba(245,158,11,0.2)' },
                  { label: 'Assignments', value: assignments.length, icon: MapPin, gradient: 'linear-gradient(135deg, #8b5cf6, #a855f7)', shadow: 'rgba(139,92,246,0.2)' },
                ].map((s, i) => (
                  <motion.div key={i} variants={item} className="stat-card">
                    <div className="icon-badge" style={{ background: s.gradient, boxShadow: `0 4px 16px ${s.shadow}`, marginBottom: '1rem' }}>
                      <s.icon className="w-5 h-5 text-white" />
                    </div>
                    <p style={{ fontSize: '2rem', fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1 }}>{s.value}</p>
                    <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)', marginTop: '0.375rem', fontWeight: 500 }}>{s.label}</p>
                  </motion.div>
                ))}
              </motion.div>

              {/* Live Positions */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                <span className="live-dot" />
                <h3 style={{ fontSize: '1.125rem', fontWeight: 700 }}>Live Bus Positions</h3>
                {livePositions.length > 0 && (
                  <span className="badge" style={{ background: 'rgba(16,185,129,0.1)', color: '#34d399' }}>
                    {livePositions.length} active
                  </span>
                )}
              </div>

              {livePositions.length === 0 ? (
                <div className="empty-state">
                  <Radio style={{ width: '32px', height: '32px', margin: '0 auto 0.75rem', opacity: 0.3 }} />
                  <p style={{ fontWeight: 500 }}>No buses currently being tracked</p>
                  <p style={{ fontSize: '0.8125rem', marginTop: '0.25rem' }}>Assign a bus to a driver to start live tracking</p>
                </div>
              ) : (
                <motion.div variants={container} initial="hidden" animate="show"
                  style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.875rem' }}>
                  {livePositions.map(pos => (
                    <motion.div key={pos.busId} variants={item} className="glass-card" style={{ padding: '1.25rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.875rem' }}>
                        <span style={{ fontWeight: 700, color: '#34d399', fontSize: '1rem' }}>{pos.busNumber}</span>
                        <span style={{ fontSize: '0.6875rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Clock style={{ width: '10px', height: '10px' }} />
                          {new Date(pos.lastUpdated).toLocaleTimeString()}
                        </span>
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                          <MapPin style={{ width: '13px', height: '13px', color: '#3b82f6' }} />
                          {pos.lat.toFixed(4)}, {pos.lng.toFixed(4)}
                        </div>
                        <div style={{ display: 'flex', gap: '1rem' }}>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                            <Gauge style={{ width: '13px', height: '13px', color: '#f59e0b' }} />
                            {pos.speed.toFixed(0)} km/h
                          </span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
                            <Navigation style={{ width: '13px', height: '13px', color: '#a855f7' }} />
                            {pos.heading.toFixed(0)}°
                          </span>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </motion.div>
              )}
            </motion.div>
          )}

          {/* ════════ BUSES ════════ */}
          {tab === 'buses' && (
            <motion.div key="buses" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3 }}>
              <h2 className="page-title">Bus Management</h2>

              {/* Add Bus Form */}
              <div className="form-row" style={{ marginBottom: '1.5rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '0.6875rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.375rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Bus Number
                  </label>
                  <input value={newBusNumber} onChange={e => setNewBusNumber(e.target.value)}
                    placeholder="e.g. OD-02-1234" className="input-field" />
                </div>
                <div style={{ width: '140px' }}>
                  <label style={{ fontSize: '0.6875rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.375rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Capacity
                  </label>
                  <input type="number" value={newBusCapacity} onChange={e => setNewBusCapacity(+e.target.value)}
                    className="input-field" />
                </div>
                <button onClick={addBus} className="btn-primary">
                  <Plus className="w-4 h-4" /> Add Bus
                </button>
              </div>

              {/* Bus List */}
              <motion.div variants={container} initial="hidden" animate="show" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                {buses.map(bus => (
                  <motion.div key={bus.id} variants={item} className="list-row">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                      <div className="icon-badge" style={{ background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.15)' }}>
                        <Bus style={{ width: '18px', height: '18px', color: '#60a5fa' }} />
                      </div>
                      <div>
                        <p style={{ fontWeight: 600 }}>{bus.busNumber}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                          Capacity: {bus.capacity} · <span style={{ color: bus.status === 'active' ? '#34d399' : '#f87171' }}>{bus.status}</span>
                        </p>
                      </div>
                    </div>
                    <button onClick={() => deleteBus(bus.id)} className="btn-danger">
                      <Trash2 className="w-3.5 h-3.5" /> Remove
                    </button>
                  </motion.div>
                ))}
              </motion.div>
              {buses.length === 0 && (
                <div className="empty-state">
                  <Bus style={{ width: '32px', height: '32px', margin: '0 auto 0.75rem', opacity: 0.3 }} />
                  <p style={{ fontWeight: 500 }}>No buses registered yet</p>
                  <p style={{ fontSize: '0.8125rem', marginTop: '0.25rem' }}>Add your first bus using the form above</p>
                </div>
              )}
            </motion.div>
          )}

          {/* ════════ DRIVERS ════════ */}
          {tab === 'drivers' && (
            <motion.div key="drivers" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3 }}>
              <h2 className="page-title">Driver Management</h2>

              {/* Active Drivers */}
              <p className="section-header">Active Drivers</p>
              <motion.div variants={container} initial="hidden" animate="show" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '2rem' }}>
                {drivers.map(d => (
                  <motion.div key={d.uid} variants={item} className="list-row" style={{ borderColor: 'rgba(16,185,129,0.12)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                      <div className="icon-badge" style={{ borderRadius: '50%', background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.15)' }}>
                        <UserCheck style={{ width: '18px', height: '18px', color: '#34d399' }} />
                      </div>
                      <div>
                        <p style={{ fontWeight: 600 }}>{d.name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{d.email}</p>
                      </div>
                    </div>
                    <button onClick={() => demoteToPassenger(d.uid)} className="btn-danger">
                      Remove Driver
                    </button>
                  </motion.div>
                ))}
              </motion.div>
              {drivers.length === 0 && (
                <div className="empty-state" style={{ marginBottom: '2rem' }}>
                  <UserCheck style={{ width: '32px', height: '32px', margin: '0 auto 0.75rem', opacity: 0.3 }} />
                  <p style={{ fontWeight: 500 }}>No drivers yet</p>
                  <p style={{ fontSize: '0.8125rem', marginTop: '0.25rem' }}>Promote a passenger below to make them a driver</p>
                </div>
              )}

              {/* All Passengers → Promote */}
              <p className="section-header">All Users (Passengers)</p>
              <motion.div variants={container} initial="hidden" animate="show" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                {allUsers.filter(u => u.role === 'passenger').map(u => (
                  <motion.div key={u.uid} variants={item} className="list-row">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                      <div className="icon-badge" style={{
                        borderRadius: '50%',
                        background: 'rgba(100,116,139,0.12)',
                        border: '1px solid rgba(100,116,139,0.15)',
                        fontSize: '0.8125rem', fontWeight: 700, color: 'var(--text-secondary)',
                      }}>
                        {u.name?.charAt(0)?.toUpperCase()}
                      </div>
                      <div>
                        <p style={{ fontWeight: 600 }}>{u.name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{u.email}</p>
                      </div>
                    </div>
                    <button onClick={() => promoteToDriver(u.uid)} className="btn-success">
                      <ChevronRight className="w-3.5 h-3.5" /> Make Driver
                    </button>
                  </motion.div>
                ))}
              </motion.div>
            </motion.div>
          )}

          {/* ════════ ASSIGNMENTS ════════ */}
          {tab === 'assignments' && (
            <motion.div key="assignments" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.3 }}>
              <h2 className="page-title">Bus → Driver Assignments</h2>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '1.5rem', lineHeight: 1.6 }}>
                Assigning a bus to a driver <strong style={{ color: '#34d399' }}>starts live GPS tracking</strong>.
                Deactivating it <strong style={{ color: '#f87171' }}>stops tracking</strong>.
              </p>

              {/* Assign Form */}
              <div className="form-row" style={{ marginBottom: '1.5rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '0.6875rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.375rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Select Bus
                  </label>
                  <select value={assignBusId} onChange={e => setAssignBusId(e.target.value)} className="input-field">
                    <option value="">Choose a bus...</option>
                    {buses.filter(b => b.status === 'active').map(b => (
                      <option key={b.id} value={b.id}>{b.busNumber}</option>
                    ))}
                  </select>
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '0.6875rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.375rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Select Driver
                  </label>
                  <select value={assignDriverId} onChange={e => setAssignDriverId(e.target.value)} className="input-field">
                    <option value="">Choose a driver...</option>
                    {drivers.map(d => (
                      <option key={d.uid} value={d.uid}>{d.name} ({d.email})</option>
                    ))}
                  </select>
                </div>
                <button onClick={assignBus} className="btn-primary">
                  <Zap className="w-4 h-4" /> Assign & Track
                </button>
              </div>

              {/* Active Assignments */}
              <motion.div variants={container} initial="hidden" animate="show" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                {assignments.map(a => (
                  <motion.div key={a.id} variants={item} className="list-row" style={{ borderColor: 'rgba(16,185,129,0.12)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Bus style={{ width: '16px', height: '16px', color: '#60a5fa' }} />
                        <span style={{ fontWeight: 600 }}>{a.busNumber || a.busId}</span>
                      </div>
                      <span style={{ color: 'var(--text-muted)', fontSize: '1.25rem' }}>→</span>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <UserCheck style={{ width: '16px', height: '16px', color: '#34d399' }} />
                        <span>{a.driverName || a.driverId}</span>
                      </div>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                        <span className="live-dot" style={{ width: '6px', height: '6px' }} />
                        Since {new Date(a.startedAt).toLocaleString()}
                      </span>
                    </div>
                    <button onClick={() => deactivateAssignment(a.id)} className="btn-danger">
                      Stop Tracking
                    </button>
                  </motion.div>
                ))}
              </motion.div>
              {assignments.length === 0 && (
                <div className="empty-state">
                  <Radio style={{ width: '32px', height: '32px', margin: '0 auto 0.75rem', opacity: 0.3 }} />
                  <p style={{ fontWeight: 500 }}>No active assignments</p>
                  <p style={{ fontSize: '0.8125rem', marginTop: '0.25rem' }}>Create an assignment above to start tracking</p>
                </div>
              )}
            </motion.div>
          )}

        </AnimatePresence>
      </main>
    </div>
  );
}

// ═══════════════ Root App ═══════════════
export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-primary)' }}>
        <div className="loader" />
      </div>
    );
  }

  if (!user) {
    return <LoginPage onLogin={() => {}} />;
  }

  return <Dashboard />;
}
