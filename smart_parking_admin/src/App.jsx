import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { Toaster } from "react-hot-toast";

import { AuthProvider } from "./contexts/AuthContext";
import ProtectedRoute from "./components/auth/ProtectedRoute";
import AdminLayout from "./components/layout/AdminLayout.jsx";

import Login from "./pages/Login.jsx";
import Home from "./pages/Home.jsx";
import Campuses from "./pages/Campuses.jsx";
import ParkingLots from "./pages/ParkingLots.jsx";
import MapEditor from "./pages/MapEditor.jsx";

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Toaster position="top-right" reverseOrder={false} />
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route element={<ProtectedRoute />}>
            <Route element={<AdminLayout />}>
              <Route index element={<Home />} />
              <Route path="campuses" element={<Campuses />} />
              <Route path="parking-lots" element={<ParkingLots />} />
              <Route path="map-editor" element={<MapEditor />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
