import { useCallback, useEffect, useMemo, useState } from 'react';
import { NavLink, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom';
import type { User } from 'firebase/auth';
import { onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup, signOut } from 'firebase/auth';
import { io } from 'socket.io-client';
import {
  Activity,
  AlertCircle,
  ArrowRight,
  Bell,
  Bus,
  Gauge,
  LayoutDashboard,
  LogOut,
  MapPin,
  Navigation,
  Plus,
  Radio,
  Route as RouteIcon,
  Save,
  Shield,
  Trash2,
  UserCheck,
  Users,
} from 'lucide-react';
import { auth, googleProvider } from './config/firebase';
import { apiFetch } from './lib/api';

const API_URL = import.meta.env.VITE_API_URL || 'https://velocity.linkitapp.in';

interface UserProfile {
  uid: string;
  email: string;
  name: string;
  role: string;
  phone?: string;
  isActive?: boolean;
}

interface BusData {
  id: string;
  busNumber: string;
  routeId?: string | null;
  routeName?: string;
  routeShortName?: string;
  capacity: number;
  status: string;
  source?: 'demo' | 'real';
  isDemo?: boolean;
}

interface RouteData {
  id: string;
  name: string;
  shortName: string;
  colorIndex: number;
  stops?: { id?: string; name: string }[];
  isActive?: boolean;
  source?: 'demo' | 'real';
  isDemo?: boolean;
}

interface Assignment {
  id: string;
  busId: string;
  driverId: string;
  busNumber: string;
  driverName: string;
  routeId?: string | null;
  routeName?: string;
  isActive: boolean;
  startedAt: string;
  source?: 'demo' | 'real';
  isDemo?: boolean;
}

interface LivePosition {
  id?: string;
  busId: string;
  busNumber: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  driverId: string;
  driverName?: string;
  routeId?: string;
  routeName?: string;
  routeShortName?: string;
  lastUpdated: string;
  status?: string;
  source?: 'demo' | 'real';
  isDemo?: boolean;
}

interface AlertData {
  id: string;
  title: string;
  body: string;
  type?: string;
  audience?: string;
  routeId?: string | null;
  busId?: string | null;
  timestamp: string;
}

interface DashboardSummary {
  totalBuses: number;
  realBuses: number;
  demoBuses: number;
  totalRoutes: number;
  drivers: number;
  passengers: number;
  admins: number;
  activeAssignments: number;
  liveBuses: number;
  recentAlerts: AlertData[];
}

type BusFormState = { id?: string; busNumber: string; capacity: number; routeId: string; status: string };
type RouteFormState = { id?: string; name: string; shortName: string; colorIndex: number; isActive: boolean };
type BroadcastFormState = { title: string; body: string; audience: string; type: string; routeId: string; busId: string };

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Request failed';
}

function emptyBusForm(): BusFormState {
  return { busNumber: '', capacity: 40, routeId: '', status: 'active' };
}

function emptyRouteForm(): RouteFormState {
  return { name: '', shortName: '', colorIndex: 0, isActive: true };
}

function emptyBroadcastForm(): BroadcastFormState {
  return { title: '', body: '', audience: 'all', type: 'service_update', routeId: '', busId: '' };
}

function MessageBanner({ error, message }: { error?: string; message?: string }) {
  if (!error && !message) return null;
  return (
    <div className={`message ${error ? 'error' : 'success'}`}>
      <AlertCircle size={16} />
      <span>{error || message}</span>
    </div>
  );
}

function StatusBadge({ value, tone = 'default' }: { value: string; tone?: 'default' | 'success' | 'warning' | 'danger' }) {
  return <span className={`status-chip tone-${tone}`}>{value}</span>;
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="empty-state">
      <p className="empty-title">{title}</p>
      <p>{body}</p>
    </div>
  );
}

function SectionHeader({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="section-head">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h2>{title}</h2>
        {description ? <p className="section-copy">{description}</p> : null}
      </div>
      {action}
    </div>
  );
}

function StatCard({
  label,
  value,
  hint,
  icon: Icon,
}: {
  label: string;
  value: number | string;
  hint?: string;
  icon: typeof Activity;
}) {
  return (
    <div className="panel stat-card">
      <div className="stat-top">
        <span className="icon-frame">
          <Icon size={16} />
        </span>
        <div>
          <p className="stat-label">{label}</p>
          {hint ? <p className="stat-hint">{hint}</p> : null}
        </div>
      </div>
      <div className="stat-value">{value}</div>
    </div>
  );
}

function LoginPage({ onLogin, sessionError }: { onLogin: () => void; sessionError?: string }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleEmail = async (event: React.FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      await signInWithEmailAndPassword(auth, email, password);
      onLogin();
    } catch (nextError) {
      const message = getErrorMessage(nextError);
      setError(message.includes('invalid') ? 'Invalid credentials' : message);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    setLoading(true);
    setError('');
    try {
      await signInWithPopup(auth, googleProvider);
      onLogin();
    } catch (nextError) {
      setError(getErrorMessage(nextError));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-shell">
      <div className="auth-panel">
        <div className="auth-brand">
          <div className="brand-mark">
            <Bus size={18} />
          </div>
          <div>
            <p className="eyebrow">Velocity Transit</p>
            <h1>Admin Console</h1>
          </div>
        </div>

        <div className="auth-copy">
          <h2>Operate the full fleet</h2>
          <p>Manage live buses, demo simulation traffic, routes, drivers, assignments, and alerts from one console.</p>
        </div>

        <MessageBanner error={sessionError || error} />

        <form className="auth-form" onSubmit={handleEmail}>
          <label className="field-label" htmlFor="email">Email</label>
          <input id="email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@company.com" className="input-field" required />

          <label className="field-label" htmlFor="password">Password</label>
          <input id="password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter password" className="input-field" required />

          <button type="submit" className="btn-primary auth-button" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="auth-divider"><span>or</span></div>

        <button className="btn-secondary auth-button" onClick={handleGoogle} disabled={loading}>
          Continue with Google
        </button>

        <p className="auth-footnote">
          Admin access is granted only to Firebase users whose email is listed in backend <code>ADMIN_EMAILS</code>.
        </p>
      </div>
    </div>
  );
}

function Dashboard() {
  const location = useLocation();
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [token, setToken] = useState('');
  const [authError, setAuthError] = useState('');
  const [actionError, setActionError] = useState('');
  const [actionMessage, setActionMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [buses, setBuses] = useState<BusData[]>([]);
  const [routes, setRoutes] = useState<RouteData[]>([]);
  const [drivers, setDrivers] = useState<UserProfile[]>([]);
  const [allUsers, setAllUsers] = useState<UserProfile[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [livePositions, setLivePositions] = useState<LivePosition[]>([]);
  const [alerts, setAlerts] = useState<AlertData[]>([]);
  const [busForm, setBusForm] = useState<BusFormState>(emptyBusForm());
  const [routeForm, setRouteForm] = useState<RouteFormState>(emptyRouteForm());
  const [broadcastForm, setBroadcastForm] = useState<BroadcastFormState>(emptyBroadcastForm());
  const [assignBusId, setAssignBusId] = useState('');
  const [assignDriverId, setAssignDriverId] = useState('');
  const [busSearch, setBusSearch] = useState('');

  const links = [
    { label: 'Overview', path: '/overview', icon: LayoutDashboard },
    { label: 'Buses', path: '/buses', icon: Bus },
    { label: 'Routes', path: '/routes', icon: RouteIcon },
    { label: 'Drivers', path: '/drivers', icon: Users },
    { label: 'Assignments', path: '/assignments', icon: Radio },
    { label: 'Alerts', path: '/alerts', icon: Bell },
  ];

  const fetchLive = useCallback(async (currentToken: string) => {
    const trackingResponse = await apiFetch('/api/tracking/live', currentToken);
    setLivePositions(trackingResponse.positions || []);
  }, []);

  const fetchAll = useCallback(async (currentToken = token, showLoader = false) => {
    if (!currentToken) return;
    if (showLoader) setLoading(true);
    else setRefreshing(true);

    try {
      const [adminResponse, busResponse, userResponse, assignmentResponse, routeResponse, alertResponse, trackingResponse] = await Promise.all([
        apiFetch('/api/admin/dashboard', currentToken),
        apiFetch('/api/buses?includeInactive=true', currentToken),
        apiFetch('/api/users', currentToken),
        apiFetch('/api/assignments?active=true', currentToken),
        apiFetch('/api/routes?includeInactive=true', currentToken),
        apiFetch('/api/notifications/history', currentToken),
        apiFetch('/api/tracking/live', currentToken),
      ]);

      const users = (userResponse.users || []) as UserProfile[];
      setSummary(adminResponse.summary || null);
      setBuses(busResponse.buses || []);
      setRoutes(routeResponse.routes || []);
      setAllUsers(users);
      setDrivers(users.filter((item) => item.role === 'driver'));
      setAssignments(assignmentResponse.assignments || []);
      setAlerts(alertResponse.alerts || []);
      setLivePositions(trackingResponse.positions || []);
    } catch (error) {
      setActionError(getErrorMessage(error));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [token]);

  const runAdminAction = useCallback(async (work: () => Promise<void>, successMessage: string) => {
    setActionLoading(true);
    setActionError('');
    setActionMessage('');
    try {
      await work();
      await fetchAll(token);
      setActionMessage(successMessage);
    } catch (error) {
      setActionError(getErrorMessage(error));
    } finally {
      setActionLoading(false);
    }
  }, [fetchAll, token]);

  useEffect(() => {
    return onAuthStateChanged(auth, async (nextUser) => {
      setUser(nextUser);
      if (nextUser) setToken(await nextUser.getIdToken());
      else {
        setToken('');
        setProfile(null);
      }
    });
  }, []);

  useEffect(() => {
    if (!user || !token) return;
    apiFetch('/api/auth/me?source=admin_web', token)
      .then((data) => {
        setAuthError('');
        setProfile(data.user);
      })
      .catch(async (error: Error) => {
        setAuthError(error.message);
        setProfile(null);
        setToken('');
        await signOut(auth);
      });
  }, [user, token]);

  useEffect(() => {
    if (!token || !profile) return;
    void fetchAll(token, true);
  }, [token, profile, fetchAll]);

  useEffect(() => {
    if (!token || !profile) return;
    const refreshId = window.setInterval(() => void fetchAll(token), 30000);
    const liveId = window.setInterval(() => void fetchLive(token), 8000);
    return () => {
      window.clearInterval(refreshId);
      window.clearInterval(liveId);
    };
  }, [fetchAll, fetchLive, profile, token]);

  useEffect(() => {
    if (!token || !profile) return;
    const socket = io(API_URL, { auth: { token } });
    socket.on('bus:position', (position: LivePosition) => {
      setLivePositions((previous) => [...previous.filter((item) => item.busId !== position.busId), position]);
    });
    socket.on('bus:offline', ({ busId }: { busId: string }) => {
      setLivePositions((previous) => previous.filter((item) => item.busId !== busId));
    });
    socket.on('live:positions', (positions: LivePosition[]) => setLivePositions(positions));
    socket.emit('get:live');
    return () => {
      socket.disconnect();
    };
  }, [profile, token]);

  const routeLabelById = useMemo(
    () => Object.fromEntries(routes.map((route) => [route.id, `${route.shortName || route.id} · ${route.name || route.id}`])) as Record<string, string>,
    [routes],
  );
  const busAssignmentsById = useMemo(
    () => Object.fromEntries(assignments.map((item) => [item.busId, item] as const)) as Record<string, Assignment>,
    [assignments],
  );
  const filteredBuses = useMemo(() => {
    const query = busSearch.trim().toLowerCase();
    if (!query) return buses;
    return buses.filter((bus) => bus.busNumber.toLowerCase().includes(query) || (routeLabelById[bus.routeId || ''] || '').toLowerCase().includes(query) || (bus.source || '').toLowerCase().includes(query));
  }, [busSearch, buses, routeLabelById]);
  const realAssignableBuses = useMemo(
    () => buses.filter((bus) => !bus.isDemo && bus.status !== 'inactive' && !busAssignmentsById[bus.id]),
    [busAssignmentsById, buses],
  );
  const availableDrivers = useMemo(
    () => drivers.filter((driver) => !assignments.some((item) => item.driverId === driver.uid)),
    [assignments, drivers],
  );
  const routeFleetCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    buses.forEach((bus) => {
      if (bus.routeId) counts[bus.routeId] = (counts[bus.routeId] || 0) + 1;
    });
    return counts;
  }, [buses]);
  const overviewStats = useMemo(() => [
    { label: 'Fleet total', value: summary?.totalBuses ?? buses.length, hint: `${summary?.realBuses ?? buses.filter((bus) => !bus.isDemo).length} real / ${summary?.demoBuses ?? buses.filter((bus) => bus.isDemo).length} demo`, icon: Bus },
    { label: 'Routes', value: summary?.totalRoutes ?? routes.length, hint: 'Live plus simulated corridors', icon: RouteIcon },
    { label: 'Drivers', value: summary?.drivers ?? drivers.length, hint: `${summary?.passengers ?? allUsers.filter((item) => item.role === 'passenger').length} passengers ready`, icon: UserCheck },
    { label: 'Assignments', value: summary?.activeAssignments ?? assignments.length, hint: `${summary?.liveBuses ?? livePositions.length} vehicles currently publishing`, icon: Radio },
  ], [allUsers, assignments.length, buses, drivers.length, livePositions.length, routes.length, summary]);

  const editBus = (bus: BusData) => {
    setBusForm({ id: bus.id, busNumber: bus.busNumber, capacity: bus.capacity, routeId: bus.routeId || '', status: bus.status || 'active' });
    setActionError('');
    setActionMessage('');
    if (location.pathname !== '/buses') navigate('/buses');
  };

  const saveBus = async () => {
    if (!busForm.busNumber.trim()) return;
    const payload = { busNumber: busForm.busNumber.trim(), capacity: busForm.capacity, routeId: busForm.routeId || null, status: busForm.status };
    if (busForm.id) {
      await runAdminAction(async () => {
        await apiFetch(`/api/buses/${busForm.id}`, token, { method: 'PATCH', body: JSON.stringify(payload) });
        setBusForm(emptyBusForm());
      }, 'Bus updated successfully.');
    } else {
      await runAdminAction(async () => {
        await apiFetch('/api/buses', token, { method: 'POST', body: JSON.stringify(payload) });
        setBusForm(emptyBusForm());
      }, 'Bus added successfully.');
    }
  };

  const editRoute = (route: RouteData) => {
    setRouteForm({ id: route.id, name: route.name, shortName: route.shortName, colorIndex: route.colorIndex || 0, isActive: route.isActive !== false });
    setActionError('');
    setActionMessage('');
    if (location.pathname !== '/routes') navigate('/routes');
  };

  const saveRoute = async () => {
    if (!routeForm.name.trim() || !routeForm.shortName.trim()) return;
    const payload = { name: routeForm.name.trim(), shortName: routeForm.shortName.trim(), colorIndex: routeForm.colorIndex, isActive: routeForm.isActive };
    if (routeForm.id) {
      await runAdminAction(async () => {
        await apiFetch(`/api/routes/${routeForm.id}`, token, { method: 'PATCH', body: JSON.stringify(payload) });
        setRouteForm(emptyRouteForm());
      }, 'Route updated successfully.');
    } else {
      await runAdminAction(async () => {
        await apiFetch('/api/routes', token, { method: 'POST', body: JSON.stringify({ ...payload, stops: [], pathPoints: [] }) });
        setRouteForm(emptyRouteForm());
      }, 'Route created successfully.');
    }
  };

  const saveRole = async (uid: string, role: 'driver' | 'passenger', message: string) => {
    await runAdminAction(async () => {
      await apiFetch(`/api/users/${uid}/role`, token, { method: 'PATCH', body: JSON.stringify({ role }) });
    }, message);
  };

  const assignBus = async () => {
    if (!assignBusId || !assignDriverId) return;
    const bus = buses.find((item) => item.id === assignBusId);
    const driver = drivers.find((item) => item.uid === assignDriverId);
    await runAdminAction(async () => {
      await apiFetch('/api/assignments', token, {
        method: 'POST',
        body: JSON.stringify({ busId: assignBusId, driverId: assignDriverId, busNumber: bus?.busNumber || '', driverName: driver?.name || '', routeId: bus?.routeId || null }),
      });
      setAssignBusId('');
      setAssignDriverId('');
    }, 'Assignment created successfully.');
  };

  const sendBroadcast = async () => {
    if (!broadcastForm.title.trim() || !broadcastForm.body.trim()) return;
    await runAdminAction(async () => {
      await apiFetch('/api/notifications/broadcast', token, {
        method: 'POST',
        body: JSON.stringify({
          title: broadcastForm.title.trim(),
          body: broadcastForm.body.trim(),
          audience: broadcastForm.audience,
          type: broadcastForm.type,
          routeId: broadcastForm.routeId || null,
          busId: broadcastForm.busId || null,
        }),
      });
      setBroadcastForm(emptyBroadcastForm());
    }, 'Broadcast sent successfully.');
  };

  if (!profile) {
    return (
      <div className="loading-shell">
        {authError ? <div className="message error wide-message"><AlertCircle size={16} /><span>{authError}</span></div> : <div className="loader-block">Loading admin session...</div>}
      </div>
    );
  }

  if (loading) {
    return (
      <div className="loading-shell">
        <div className="loader-block">Loading operations console...</div>
      </div>
    );
  }

  return (
    <div className="dashboard-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-mark"><Bus size={18} /></div>
          <div><p className="eyebrow">Velocity Transit</p><h1>Admin Console</h1></div>
        </div>

        <div className="sidebar-summary panel subtle-panel">
          <p className="eyebrow">Live State</p>
          <div className="summary-line"><span>Vehicles online</span><strong>{livePositions.length}</strong></div>
          <div className="summary-line"><span>Assignments</span><strong>{assignments.length}</strong></div>
          <div className="summary-line"><span>Refresh</span><strong>{refreshing ? 'Syncing' : 'Ready'}</strong></div>
        </div>

        <nav className="sidebar-nav">
          {links.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink key={item.path} to={item.path} className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
                <span className="nav-item-left"><Icon size={16} /><span>{item.label}</span></span>
              </NavLink>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="operator-card">
            <div className="operator-avatar">{profile.name?.charAt(0)?.toUpperCase() || 'A'}</div>
            <div><p className="operator-name">{profile.name}</p><p className="operator-role"><Shield size={12} />Admin</p></div>
          </div>
          <button className="signout-button" onClick={() => signOut(auth)}><LogOut size={14} />Sign Out</button>
        </div>
      </aside>

      <main className="main-panel">
        <MessageBanner error={actionError} message={actionMessage} />
        <Routes>
          <Route path="/" element={<Navigate to="/overview" replace />} />
          <Route path="/overview" element={<section className="content-section"><SectionHeader eyebrow="Operations" title="Fleet overview" description="Real buses from Firestore and demo buses from the simulation layer are both visible here." action={<button className="btn-secondary" onClick={() => void fetchAll(token)}><Activity size={15} />Refresh</button>} /><div className="stats-grid">{overviewStats.map((stat) => <StatCard key={stat.label} {...stat} />)}</div><div className="split-layout"><div className="panel"><div className="panel-head"><div><p className="eyebrow">Tracking</p><h3>Live vehicle feed</h3></div><StatusBadge value={`${livePositions.length} online`} tone="success" /></div>{livePositions.length === 0 ? <EmptyState title="No live buses" body="Assignments are active, but no buses are publishing coordinates right now." /> : <div className="card-grid">{livePositions.slice(0, 9).map((position) => <div key={position.busId} className="detail-card"><div className="detail-row primary"><span>{position.busNumber}</span><StatusBadge value={position.isDemo ? 'Demo' : 'Real'} tone={position.isDemo ? 'warning' : 'success'} /></div><div className="detail-row"><MapPin size={13} /><span>{position.lat.toFixed(4)}, {position.lng.toFixed(4)}</span></div><div className="detail-row split"><span><Gauge size={13} />{position.speed.toFixed(0)} km/h</span><span><Navigation size={13} />{position.heading.toFixed(0)} deg</span></div><div className="detail-row split"><span>{position.routeShortName || routeLabelById[position.routeId || ''] || 'No route'}</span><span>{new Date(position.lastUpdated).toLocaleTimeString()}</span></div></div>)}</div>}</div><div className="panel"><div className="panel-head"><div><p className="eyebrow">Alerts</p><h3>Recent notifications</h3></div><StatusBadge value={`${alerts.length} logged`} /></div><div className="stack">{(summary?.recentAlerts?.length ? summary.recentAlerts : alerts.slice(0, 5)).map((alert) => <div key={alert.id} className="list-row compact-row"><div className="list-meta"><span className="icon-frame round"><Bell size={14} /></span><div><p className="list-title">{alert.title}</p><p className="list-subtitle">{alert.body}</p></div></div><span className="list-subtitle inline">{new Date(alert.timestamp).toLocaleString()}</span></div>)}{alerts.length === 0 ? <EmptyState title="No alerts yet" body="Broadcasts and trip notifications will appear here after they are sent." /> : null}</div></div></div></section>} />
          <Route path="/buses" element={<section className="content-section"><SectionHeader eyebrow="Inventory" title="Bus management" description="Create and update real buses. Demo buses remain visible but read-only." /><div className="panel form-panel multi-row-form"><div className="field-group grow"><label className="field-label">Bus number</label><input className="input-field" value={busForm.busNumber} onChange={(event) => setBusForm((current) => ({ ...current, busNumber: event.target.value }))} placeholder="OD-02-1234" /></div><div className="field-group compact"><label className="field-label">Capacity</label><input className="input-field" type="number" value={busForm.capacity} onChange={(event) => setBusForm((current) => ({ ...current, capacity: Number(event.target.value) || 0 }))} /></div><div className="field-group grow"><label className="field-label">Route</label><select className="input-field" value={busForm.routeId} onChange={(event) => setBusForm((current) => ({ ...current, routeId: event.target.value }))}><option value="">No route yet</option>{routes.map((route) => <option key={route.id} value={route.id}>{route.shortName} · {route.name}</option>)}</select></div><div className="field-group compact"><label className="field-label">Status</label><select className="input-field" value={busForm.status} onChange={(event) => setBusForm((current) => ({ ...current, status: event.target.value }))}><option value="active">Active</option><option value="maintenance">Maintenance</option><option value="inactive">Inactive</option></select></div><button className="btn-primary" onClick={() => void saveBus()} disabled={actionLoading}><Save size={15} />{busForm.id ? 'Save Bus' : 'Add Bus'}</button><button className="btn-secondary" onClick={() => setBusForm(emptyBusForm())} disabled={actionLoading}>Reset</button></div><div className="panel toolbar-panel"><div className="field-group grow"><label className="field-label">Search fleet</label><input className="input-field" value={busSearch} onChange={(event) => setBusSearch(event.target.value)} placeholder="Search by bus number, route, or source" /></div></div><div className="stack">{filteredBuses.map((bus) => <div key={bus.id} className="list-row"><div className="list-meta"><span className="icon-frame"><Bus size={15} /></span><div><div className="title-line"><p className="list-title">{bus.busNumber}</p><StatusBadge value={bus.isDemo ? 'Demo' : 'Real'} tone={bus.isDemo ? 'warning' : 'success'} /><StatusBadge value={bus.status} tone={bus.status === 'inactive' ? 'danger' : 'default'} /></div><p className="list-subtitle">Capacity {bus.capacity} · {routeLabelById[bus.routeId || ''] || 'No route'} · {busAssignmentsById[bus.id] ? `Assigned to ${busAssignmentsById[bus.id].driverName}` : 'Unassigned'}</p></div></div>{bus.isDemo ? <span className="list-subtitle inline">Read-only simulation bus</span> : <div className="button-row"><button className="btn-secondary" onClick={() => editBus(bus)}>Edit</button><button className="btn-danger" onClick={() => void runAdminAction(async () => { await apiFetch(`/api/buses/${bus.id}`, token, { method: 'DELETE' }); }, 'Bus deactivated successfully.')} disabled={actionLoading}><Trash2 size={14} />Deactivate</button></div>}</div>)}{filteredBuses.length === 0 ? <EmptyState title="No buses found" body="Try a different search or add the first bus for your live fleet." /> : null}</div></section>} />
          <Route path="/routes" element={<section className="content-section"><SectionHeader eyebrow="Network" title="Route management" description="Create live routes for the backend and keep visibility on read-only demo corridors." /><div className="panel form-panel multi-row-form"><div className="field-group grow"><label className="field-label">Route name</label><input className="input-field" value={routeForm.name} onChange={(event) => setRouteForm((current) => ({ ...current, name: event.target.value }))} placeholder="North Connector" /></div><div className="field-group compact"><label className="field-label">Short name</label><input className="input-field" value={routeForm.shortName} onChange={(event) => setRouteForm((current) => ({ ...current, shortName: event.target.value }))} placeholder="N1" /></div><div className="field-group compact"><label className="field-label">Color index</label><input className="input-field" type="number" value={routeForm.colorIndex} onChange={(event) => setRouteForm((current) => ({ ...current, colorIndex: Number(event.target.value) || 0 }))} /></div><div className="field-group compact"><label className="field-label">Status</label><select className="input-field" value={routeForm.isActive ? 'active' : 'inactive'} onChange={(event) => setRouteForm((current) => ({ ...current, isActive: event.target.value === 'active' }))}><option value="active">Active</option><option value="inactive">Inactive</option></select></div><button className="btn-primary" onClick={() => void saveRoute()} disabled={actionLoading}><Plus size={15} />{routeForm.id ? 'Save Route' : 'Create Route'}</button><button className="btn-secondary" onClick={() => setRouteForm(emptyRouteForm())} disabled={actionLoading}>Reset</button></div><div className="stack">{routes.map((route) => <div key={route.id} className="list-row"><div className="list-meta"><span className="icon-frame"><RouteIcon size={15} /></span><div><div className="title-line"><p className="list-title">{route.shortName} · {route.name}</p><StatusBadge value={route.isDemo ? 'Demo' : 'Real'} tone={route.isDemo ? 'warning' : 'success'} /><StatusBadge value={route.isActive === false ? 'inactive' : 'active'} tone={route.isActive === false ? 'danger' : 'default'} /></div><p className="list-subtitle">{routeFleetCounts[route.id] || 0} buses · {route.stops?.length || 0} stops</p></div></div>{route.isDemo ? <span className="list-subtitle inline">Simulation route</span> : <div className="button-row"><button className="btn-secondary" onClick={() => editRoute(route)}>Edit</button><button className="btn-danger" onClick={() => void runAdminAction(async () => { await apiFetch(`/api/routes/${route.id}`, token, { method: 'DELETE' }); }, 'Route archived successfully.')} disabled={actionLoading}><Trash2 size={14} />Archive</button></div>}</div>)}</div></section>} />
          <Route path="/drivers" element={<section className="content-section"><SectionHeader eyebrow="People" title="Driver management" description="Promote passenger accounts to drivers and free up driver seats when needed." /><div className="split-layout"><div className="panel"><div className="panel-head"><div><p className="eyebrow">Drivers</p><h3>Active driver accounts</h3></div><StatusBadge value={`${drivers.length} active`} /></div><div className="stack">{drivers.length === 0 ? <EmptyState title="No drivers available" body="Promote a passenger account to start assigning buses." /> : null}{drivers.map((driver) => <div key={driver.uid} className="list-row"><div className="list-meta"><span className="icon-frame round"><UserCheck size={15} /></span><div><p className="list-title">{driver.name}</p><p className="list-subtitle">{driver.email}</p></div></div><button className="btn-danger" onClick={() => void saveRole(driver.uid, 'passenger', 'Driver moved back to passenger.')} disabled={actionLoading}>Remove Driver</button></div>)}</div></div><div className="panel"><div className="panel-head"><div><p className="eyebrow">Promotion queue</p><h3>Passenger accounts</h3></div><StatusBadge value={`${allUsers.filter((item) => item.role === 'passenger').length} waiting`} /></div><div className="stack">{allUsers.filter((item) => item.role === 'passenger').length === 0 ? <EmptyState title="No passengers available" body="User registrations will appear here and can be promoted to drivers." /> : null}{allUsers.filter((item) => item.role === 'passenger').map((item) => <div key={item.uid} className="list-row"><div className="list-meta"><span className="icon-frame round text-avatar">{item.name?.charAt(0)?.toUpperCase() || 'U'}</span><div><p className="list-title">{item.name}</p><p className="list-subtitle">{item.email}</p></div></div><button className="btn-secondary" onClick={() => void saveRole(item.uid, 'driver', 'User promoted to driver.')} disabled={actionLoading}><ArrowRight size={14} />Make Driver</button></div>)}</div></div></div></section>} />
          <Route path="/assignments" element={<section className="content-section"><SectionHeader eyebrow="Dispatch" title="Assignments" description="Dispatch real buses to real drivers while keeping demo trips visible in the same timeline." /><div className="panel form-panel"><div className="field-group grow"><label className="field-label">Bus</label><select className="input-field" value={assignBusId} onChange={(event) => setAssignBusId(event.target.value)}><option value="">Choose a real bus</option>{realAssignableBuses.map((item) => <option key={item.id} value={item.id}>{item.busNumber} · {routeLabelById[item.routeId || ''] || 'No route'}</option>)}</select></div><div className="field-group grow"><label className="field-label">Driver</label><select className="input-field" value={assignDriverId} onChange={(event) => setAssignDriverId(event.target.value)}><option value="">Choose a driver</option>{availableDrivers.map((item) => <option key={item.uid} value={item.uid}>{item.name} ({item.email})</option>)}</select></div><button className="btn-primary" onClick={() => void assignBus()} disabled={actionLoading}><Radio size={15} />Assign</button></div><div className="stack">{assignments.length === 0 ? <EmptyState title="No active assignments" body="Dispatch a bus to a driver to start live tracking." /> : null}{assignments.map((assignment) => <div key={assignment.id} className="list-row"><div className="assignment-meta"><span className="list-title">{assignment.busNumber || assignment.busId}</span><ArrowRight size={14} /><span className="list-title">{assignment.driverName || assignment.driverId}</span><StatusBadge value={assignment.isDemo ? 'Demo' : 'Real'} tone={assignment.isDemo ? 'warning' : 'success'} />{assignment.routeId ? <span className="list-subtitle inline">{routeLabelById[assignment.routeId] || assignment.routeName || assignment.routeId}</span> : null}<span className="list-subtitle inline">Since {new Date(assignment.startedAt).toLocaleString()}</span></div>{assignment.isDemo ? <span className="list-subtitle inline">Auto-running demo assignment</span> : <button className="btn-danger" onClick={() => void runAdminAction(async () => { await apiFetch(`/api/assignments/${assignment.id}/deactivate`, token, { method: 'PATCH' }); }, 'Assignment stopped successfully.')} disabled={actionLoading}>Stop Tracking</button>}</div>)}</div></section>} />
          <Route path="/alerts" element={<section className="content-section"><SectionHeader eyebrow="Comms" title="Alerts and broadcasts" description="Push operational messages to passengers, drivers, admins, or everyone." /><div className="panel form-panel multi-row-form"><div className="field-group grow"><label className="field-label">Title</label><input className="input-field" value={broadcastForm.title} onChange={(event) => setBroadcastForm((current) => ({ ...current, title: event.target.value }))} placeholder="Service advisory" /></div><div className="field-group compact"><label className="field-label">Audience</label><select className="input-field" value={broadcastForm.audience} onChange={(event) => setBroadcastForm((current) => ({ ...current, audience: event.target.value }))}><option value="all">All</option><option value="passenger">Passengers</option><option value="driver">Drivers</option><option value="admin">Admins</option></select></div><div className="field-group compact"><label className="field-label">Type</label><select className="input-field" value={broadcastForm.type} onChange={(event) => setBroadcastForm((current) => ({ ...current, type: event.target.value }))}><option value="service_update">Service update</option><option value="delay">Delay</option><option value="route_change">Route change</option><option value="trip_started">Trip started</option><option value="trip_completed">Trip completed</option></select></div><div className="field-group grow"><label className="field-label">Route scope</label><select className="input-field" value={broadcastForm.routeId} onChange={(event) => setBroadcastForm((current) => ({ ...current, routeId: event.target.value }))}><option value="">All routes</option>{routes.map((route) => <option key={route.id} value={route.id}>{route.shortName} · {route.name}</option>)}</select></div><div className="field-group grow"><label className="field-label">Bus scope</label><select className="input-field" value={broadcastForm.busId} onChange={(event) => setBroadcastForm((current) => ({ ...current, busId: event.target.value }))}><option value="">All buses</option>{buses.map((bus) => <option key={bus.id} value={bus.id}>{bus.busNumber}</option>)}</select></div><div className="field-group full-width"><label className="field-label">Message</label><textarea className="input-field textarea-field" value={broadcastForm.body} onChange={(event) => setBroadcastForm((current) => ({ ...current, body: event.target.value }))} placeholder="Write the service message to deliver..." /></div><button className="btn-primary" onClick={() => void sendBroadcast()} disabled={actionLoading}><Bell size={15} />Send Broadcast</button></div><div className="stack">{alerts.map((alert) => <div key={alert.id} className="list-row"><div className="list-meta"><span className="icon-frame round"><Bell size={14} /></span><div><div className="title-line"><p className="list-title">{alert.title}</p><StatusBadge value={alert.audience || 'all'} /></div><p className="list-subtitle">{alert.body}</p></div></div><span className="list-subtitle inline">{new Date(alert.timestamp).toLocaleString()}</span></div>)}</div></section>} />
          <Route path="*" element={<Navigate to="/overview" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [sessionError, setSessionError] = useState('');

  useEffect(() => {
    return onAuthStateChanged(auth, (nextUser) => {
      setUser(nextUser);
      if (nextUser) setSessionError('');
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="loading-shell">
        <div className="loader-block">Loading console...</div>
      </div>
    );
  }

  if (!user) {
    return <LoginPage onLogin={() => setSessionError('')} sessionError={sessionError} />;
  }

  return <Dashboard />;
}
