import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { Toaster } from 'react-hot-toast';
import AdminLayout from "./components/layout/AdminLayout.jsx";

import Home from "./pages/Home.jsx";
import MapEditor from "./pages/MapEditor.jsx";

export default function App() {
  return (
    <BrowserRouter>
      <Toaster position="top-right" reverseOrder={false} />
      <Routes>
        <Route element={<AdminLayout />}>
          <Route index element={<Home />} />
          <Route path="map-editor" element={<MapEditor />} />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
