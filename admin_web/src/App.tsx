import { useCallback, useEffect, useMemo, useState } from 'react';
import { auth, googleProvider } from './config/firebase';
import type { User } from 'firebase/auth';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from 'firebase/auth';
import { io } from 'socket.io-client';
import {
  Activity,
  AlertCircle,
  ArrowRight,
  Bus,
  Gauge,
  LogOut,
  MapPin,
  Navigation,
  Plus,
  Radio,
  Shield,
  Trash2,
  UserCheck,
  Users,
} from 'lucide-react';
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
  routeId?: string;
  capacity: number;
  status: string;
}

interface RouteData {
  id: string;
  name: string;
  shortName: string;
}

interface Assignment {
  id: string;
  busId: string;
  driverId: string;
  busNumber: string;
  driverName: string;
  routeId?: string;
  isActive: boolean;
  startedAt: string;
}

interface LivePosition {
  busId: string;
  busNumber: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  driverId: string;
  lastUpdated: string;
}

type TabId = 'overview' | 'buses' | 'drivers' | 'assignments';

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return 'Request failed';
}

function LoginPage({
  onLogin,
  sessionError,
}: {
  onLogin: () => void;
  sessionError?: string;
}) {
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
    } catch (error) {
      const message = getErrorMessage(error);
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
    } catch (error) {
      setError(getErrorMessage(error));
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
          <h2>Secure fleet control</h2>
          <p>
            Black-and-white operations console for bus inventory, driver roles,
            live assignments, and tracking visibility.
          </p>
        </div>

        {(sessionError || error) && (
          <div className="message error">
            <AlertCircle size={16} />
            <span>{sessionError || error}</span>
          </div>
        )}

        <form className="auth-form" onSubmit={handleEmail}>
          <label className="field-label" htmlFor="email">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="admin@company.com"
            className="input-field"
            required
          />

          <label className="field-label" htmlFor="password">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="Enter password"
            className="input-field"
            required
          />

          <button type="submit" className="btn-primary auth-button" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="auth-divider">
          <span>or</span>
        </div>

        <button className="btn-secondary auth-button" onClick={handleGoogle} disabled={loading}>
          Continue with Google
        </button>

        <p className="auth-footnote">
          Admin access is granted only to Firebase users whose email is listed in
          backend <code>ADMIN_EMAILS</code>.
        </p>
      </div>
    </div>
  );
}

function Dashboard() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [tab, setTab] = useState<TabId>('overview');
  const [token, setToken] = useState('');
  const [authError, setAuthError] = useState('');
  const [actionError, setActionError] = useState('');
  const [actionMessage, setActionMessage] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const [buses, setBuses] = useState<BusData[]>([]);
  const [routes, setRoutes] = useState<RouteData[]>([]);
  const [drivers, setDrivers] = useState<UserProfile[]>([]);
  const [allUsers, setAllUsers] = useState<UserProfile[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [livePositions, setLivePositions] = useState<LivePosition[]>([]);

  const [newBusNumber, setNewBusNumber] = useState('');
  const [newBusCapacity, setNewBusCapacity] = useState(40);
  const [newBusRouteId, setNewBusRouteId] = useState('');
  const [assignBusId, setAssignBusId] = useState('');
  const [assignDriverId, setAssignDriverId] = useState('');

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

    const socket = io(API_URL, { auth: { token } });
    socket.on('bus:position', (position: LivePosition) => {
      setLivePositions((previous) => {
        const index = previous.findIndex((item) => item.busId == position.busId);
        if (index >= 0) {
          const next = [...previous];
          next[index] = position;
          return next;
        }
        return [...previous, position];
      });
    });
    socket.on('bus:offline', ({ busId }: { busId: string }) => {
      setLivePositions((previous) => previous.filter((item) => item.busId !== busId));
    });
    socket.on('live:positions', (positions: LivePosition[]) => setLivePositions(positions));
    socket.emit('get:live');

    return () => {
      socket.disconnect();
    };
  }, [token, profile]);

  const fetchAll = useCallback(async () => {
    if (!token) return;

    try {
      const [busResponse, userResponse, assignmentResponse, routeResponse] = await Promise.all([
        apiFetch('/api/buses', token),
        apiFetch('/api/users', token),
        apiFetch('/api/assignments?active=true', token),
        apiFetch('/api/routes', token),
      ]);

      const users = userResponse.users || [];
      setBuses(busResponse.buses || []);
      setAllUsers(users);
      setDrivers(users.filter((item: UserProfile) => item.role === 'driver'));
      setAssignments(assignmentResponse.assignments || []);
      setRoutes(routeResponse.routes || []);
    } catch (error) {
      console.error('Fetch error:', error);
      setActionError(getErrorMessage(error));
    }
  }, [token]);

  const runAdminAction = useCallback(
    async (work: () => Promise<void>, successMessage: string) => {
      setActionLoading(true);
      setActionError('');
      setActionMessage('');
      try {
        await work();
        await fetchAll();
        setActionMessage(successMessage);
      } catch (error) {
        setActionError(getErrorMessage(error));
      } finally {
        setActionLoading(false);
      }
    },
    [fetchAll],
  );

  useEffect(() => {
    if (!token) return;

    const timeoutId = window.setTimeout(() => {
      void fetchAll();
    }, 0);

    return () => {
      window.clearTimeout(timeoutId);
    };
  }, [token, fetchAll]);

  useEffect(() => {
    return onAuthStateChanged(auth, async (nextUser) => {
      setUser(nextUser);
      if (nextUser) {
        const nextToken = await nextUser.getIdToken();
        setToken(nextToken);
      } else {
        setToken('');
        setProfile(null);
      }
    });
  }, []);

  const addBus = async () => {
    if (!newBusNumber.trim()) return;
    await runAdminAction(async () => {
      await apiFetch('/api/buses', token, {
        method: 'POST',
        body: JSON.stringify({
          busNumber: newBusNumber,
          capacity: newBusCapacity,
          routeId: newBusRouteId || null,
        }),
      });
      setNewBusNumber('');
      setNewBusCapacity(40);
      setNewBusRouteId('');
    }, 'Bus added successfully.');
  };

  const deleteBus = async (id: string) => {
    await runAdminAction(async () => {
      await apiFetch(`/api/buses/${id}`, token, { method: 'DELETE' });
    }, 'Bus updated successfully.');
  };

  const promoteToDriver = async (uid: string) => {
    await runAdminAction(async () => {
      await apiFetch(`/api/users/${uid}/role`, token, {
        method: 'PATCH',
        body: JSON.stringify({ role: 'driver' }),
      });
    }, 'User promoted to driver.');
  };

  const demoteToPassenger = async (uid: string) => {
    await runAdminAction(async () => {
      await apiFetch(`/api/users/${uid}/role`, token, {
        method: 'PATCH',
        body: JSON.stringify({ role: 'passenger' }),
      });
    }, 'Driver moved back to passenger.');
  };

  const assignBus = async () => {
    if (!assignBusId || !assignDriverId) return;
    const bus = buses.find((item) => item.id === assignBusId);
    const driver = drivers.find((item) => item.uid === assignDriverId);
    await runAdminAction(async () => {
      await apiFetch('/api/assignments', token, {
        method: 'POST',
        body: JSON.stringify({
          busId: assignBusId,
          driverId: assignDriverId,
          busNumber: bus?.busNumber || '',
          driverName: driver?.name || '',
          routeId: bus?.routeId || null,
        }),
      });
      setAssignBusId('');
      setAssignDriverId('');
    }, 'Assignment created successfully.');
  };

  const deactivateAssignment = async (id: string) => {
    await runAdminAction(async () => {
      await apiFetch(`/api/assignments/${id}/deactivate`, token, { method: 'PATCH' });
    }, 'Assignment stopped successfully.');
  };

  const routeLabelById = useMemo(
    () =>
      Object.fromEntries(
        routes.map((route) => [
          route.id,
          `${route.shortName || route.id} · ${route.name || route.id}`,
        ]),
      ) as Record<string, string>,
    [routes],
  );

  const tabs = [
    { id: 'overview' as const, label: 'Overview', icon: Activity },
    { id: 'buses' as const, label: 'Buses', icon: Bus },
    { id: 'drivers' as const, label: 'Drivers', icon: Users },
    { id: 'assignments' as const, label: 'Assignments', icon: Radio },
  ];

  const overviewStats = useMemo(
    () => [
      { label: 'Total buses', value: buses.length, icon: Bus },
      { label: 'Driver accounts', value: drivers.length, icon: UserCheck },
      { label: 'Live positions', value: livePositions.length, icon: Radio },
      { label: 'Assignments', value: assignments.length, icon: MapPin },
    ],
    [assignments.length, buses.length, drivers.length, livePositions.length],
  );

  if (!profile) {
    return (
      <div className="loading-shell">
        {authError ? (
          <div className="message error wide-message">
            <AlertCircle size={16} />
            <span>{authError}</span>
          </div>
        ) : (
          <div className="loader-block">Loading admin session...</div>
        )}
      </div>
    );
  }

  return (
    <div className="dashboard-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-mark">
            <Bus size={18} />
          </div>
          <div>
            <p className="eyebrow">Velocity Transit</p>
            <h1>Admin Console</h1>
          </div>
        </div>

        <nav className="sidebar-nav">
          {tabs.map((item) => {
            const Icon = item.icon;
            const isActive = tab === item.id;
            return (
              <button
                key={item.id}
                className={`nav-item${isActive ? ' active' : ''}`}
                onClick={() => setTab(item.id)}
              >
                <span className="nav-item-left">
                  <Icon size={16} />
                  <span>{item.label}</span>
                </span>
                {item.id === 'assignments' && assignments.length > 0 && (
                  <span className="pill">{assignments.length}</span>
                )}
                {item.id === 'overview' && livePositions.length > 0 && (
                  <span className="status-chip">Live</span>
                )}
              </button>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="operator-card">
            <div className="operator-avatar">{profile.name?.charAt(0)?.toUpperCase() || 'A'}</div>
            <div>
              <p className="operator-name">{profile.name}</p>
              <p className="operator-role">
                <Shield size={12} />
                Admin
              </p>
            </div>
          </div>

          <button className="signout-button" onClick={() => signOut(auth)}>
            <LogOut size={14} />
            Sign Out
          </button>
        </div>
      </aside>

      <main className="main-panel">
        {(actionError || actionMessage) && (
          <div className={`message ${actionError ? 'error' : 'success'}`}>
            <AlertCircle size={16} />
            <span>{actionError || actionMessage}</span>
          </div>
        )}

        {tab === 'overview' && (
          <section className="content-section">
            <div className="section-head">
              <div>
                <p className="eyebrow">Operations</p>
                <h2>Fleet overview</h2>
              </div>
            </div>

            <div className="stats-grid">
              {overviewStats.map((stat) => {
                const Icon = stat.icon;
                return (
                  <div key={stat.label} className="panel">
                    <div className="stat-top">
                      <span className="icon-frame">
                        <Icon size={16} />
                      </span>
                      <span className="stat-label">{stat.label}</span>
                    </div>
                    <div className="stat-value">{stat.value}</div>
                  </div>
                );
              })}
            </div>

            <div className="panel">
              <div className="panel-head">
                <div>
                  <p className="eyebrow">Tracking</p>
                  <h3>Live bus positions</h3>
                </div>
                <span className="status-chip">{livePositions.length} active</span>
              </div>

              {livePositions.length === 0 ? (
                <div className="empty-state">
                  <p>No buses are publishing live positions right now.</p>
                </div>
              ) : (
                <div className="card-grid">
                  {livePositions.map((position) => (
                    <div key={position.busId} className="detail-card">
                      <div className="detail-row primary">
                        <span>{position.busNumber}</span>
                        <span>{new Date(position.lastUpdated).toLocaleTimeString()}</span>
                      </div>
                      <div className="detail-row">
                        <span>
                          <MapPin size={13} />
                          {position.lat.toFixed(4)}, {position.lng.toFixed(4)}
                        </span>
                      </div>
                      <div className="detail-row split">
                        <span>
                          <Gauge size={13} />
                          {position.speed.toFixed(0)} km/h
                        </span>
                        <span>
                          <Navigation size={13} />
                          {position.heading.toFixed(0)} deg
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        )}

        {tab === 'buses' && (
          <section className="content-section">
            <div className="section-head">
              <div>
                <p className="eyebrow">Inventory</p>
                <h2>Bus management</h2>
              </div>
            </div>

            <div className="panel form-panel">
              <div className="field-group grow">
                <label className="field-label">Bus number</label>
                <input
                  className="input-field"
                  value={newBusNumber}
                  onChange={(event) => setNewBusNumber(event.target.value)}
                  placeholder="e.g. OD-02-1234"
                />
              </div>
              <div className="field-group compact">
                <label className="field-label">Capacity</label>
                <input
                  className="input-field"
                  type="number"
                  value={newBusCapacity}
                  onChange={(event) => setNewBusCapacity(Number(event.target.value))}
                />
              </div>
              <div className="field-group grow">
                <label className="field-label">Route</label>
                <select
                  className="input-field"
                  value={newBusRouteId}
                  onChange={(event) => setNewBusRouteId(event.target.value)}
                >
                  <option value="">No route yet</option>
                  {routes.map((route) => (
                    <option key={route.id} value={route.id}>
                      {route.shortName} · {route.name}
                    </option>
                  ))}
                </select>
              </div>
              <button className="btn-primary" onClick={addBus} disabled={actionLoading}>
                <Plus size={15} />
                {actionLoading ? 'Saving...' : 'Add Bus'}
              </button>
            </div>

            <div className="stack">
              {buses.map((bus) => (
                <div key={bus.id} className="list-row">
                  <div className="list-meta">
                    <span className="icon-frame">
                      <Bus size={15} />
                    </span>
                    <div>
                      <p className="list-title">{bus.busNumber}</p>
                      <p className="list-subtitle">
                        Capacity {bus.capacity} · {bus.status}
                      </p>
                    </div>
                  </div>
                  <button className="btn-danger" onClick={() => deleteBus(bus.id)} disabled={actionLoading}>
                    <Trash2 size={14} />
                    Remove
                  </button>
                </div>
              ))}
            </div>
          </section>
        )}

        {tab === 'drivers' && (
          <section className="content-section">
            <div className="section-head">
              <div>
                <p className="eyebrow">People</p>
                <h2>Driver management</h2>
              </div>
            </div>

            <div className="split-layout">
              <div className="panel">
                <div className="panel-head">
                  <div>
                    <p className="eyebrow">Drivers</p>
                    <h3>Active driver accounts</h3>
                  </div>
                </div>

                <div className="stack">
                  {drivers.length === 0 && (
                    <div className="empty-state">
                      <p>No driver accounts found.</p>
                    </div>
                  )}
                  {drivers.map((driver) => (
                    <div key={driver.uid} className="list-row">
                      <div className="list-meta">
                        <span className="icon-frame round">
                          <UserCheck size={15} />
                        </span>
                        <div>
                          <p className="list-title">{driver.name}</p>
                          <p className="list-subtitle">{driver.email}</p>
                        </div>
                      </div>
                        <button className="btn-danger" onClick={() => demoteToPassenger(driver.uid)} disabled={actionLoading}>
                          Remove Driver
                        </button>
                    </div>
                  ))}
                </div>
              </div>

              <div className="panel">
                <div className="panel-head">
                  <div>
                    <p className="eyebrow">Promotion queue</p>
                    <h3>Passenger accounts</h3>
                  </div>
                </div>

                <div className="stack">
                  {allUsers.filter((item) => item.role === 'passenger').length === 0 && (
                    <div className="empty-state">
                      <p>No passenger accounts available to promote.</p>
                    </div>
                  )}
                  {allUsers
                    .filter((item) => item.role === 'passenger')
                    .map((item) => (
                      <div key={item.uid} className="list-row">
                        <div className="list-meta">
                          <span className="icon-frame round text-avatar">
                            {item.name?.charAt(0)?.toUpperCase() || 'U'}
                          </span>
                          <div>
                            <p className="list-title">{item.name}</p>
                            <p className="list-subtitle">{item.email}</p>
                          </div>
                        </div>
                        <button className="btn-secondary" onClick={() => promoteToDriver(item.uid)} disabled={actionLoading}>
                          <ArrowRight size={14} />
                          {actionLoading ? 'Updating...' : 'Make Driver'}
                        </button>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </section>
        )}

        {tab === 'assignments' && (
          <section className="content-section">
            <div className="section-head">
              <div>
                <p className="eyebrow">Dispatch</p>
                <h2>Assignments</h2>
              </div>
            </div>

            <div className="panel form-panel">
              <div className="field-group grow">
                <label className="field-label">Bus</label>
                <select
                  className="input-field"
                  value={assignBusId}
                  onChange={(event) => setAssignBusId(event.target.value)}
                >
                  <option value="">Choose a bus</option>
                  {buses
                    .filter((item) => item.status === 'active')
                    .map((item) => (
                      <option key={item.id} value={item.id}>
                        {item.busNumber} {item.routeId ? `· ${routeLabelById[item.routeId] || item.routeId}` : '· No route'}
                      </option>
                    ))}
                </select>
              </div>

              <div className="field-group grow">
                <label className="field-label">Driver</label>
                <select
                  className="input-field"
                  value={assignDriverId}
                  onChange={(event) => setAssignDriverId(event.target.value)}
                >
                  <option value="">Choose a driver</option>
                  {drivers.map((item) => (
                    <option key={item.uid} value={item.uid}>
                      {item.name} ({item.email})
                    </option>
                  ))}
                </select>
              </div>

              <button className="btn-primary" onClick={assignBus} disabled={actionLoading}>
                <Radio size={15} />
                {actionLoading ? 'Assigning...' : 'Assign'}
              </button>
            </div>

            <div className="stack">
              {assignments.length === 0 && (
                <div className="empty-state">
                  <p>No active assignments yet.</p>
                </div>
              )}
              {assignments.map((assignment) => (
                <div key={assignment.id} className="list-row">
                  <div className="assignment-meta">
                    <span className="list-title">{assignment.busNumber || assignment.busId}</span>
                    <ArrowRight size={14} />
                    <span className="list-title">{assignment.driverName || assignment.driverId}</span>
                    {assignment.routeId && (
                      <span className="list-subtitle inline">
                        {routeLabelById[assignment.routeId] || assignment.routeId}
                      </span>
                    )}
                    <span className="list-subtitle inline">
                      Since {new Date(assignment.startedAt).toLocaleString()}
                    </span>
                  </div>
                  <button className="btn-danger" onClick={() => deactivateAssignment(assignment.id)} disabled={actionLoading}>
                    Stop Tracking
                  </button>
                </div>
              ))}
            </div>
          </section>
        )}
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
      if (nextUser) {
        setSessionError('');
      }
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
