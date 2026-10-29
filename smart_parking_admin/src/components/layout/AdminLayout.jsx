import { Outlet } from "react-router-dom";
import Sidebar from "./Sidebar.jsx";
import Navbar from "./Navbar.jsx";

export default function AdminLayout() {
    return (
        <div className="admin-layout">
            <Sidebar />

            <div className="admin-main">
                <Navbar />

                <main className="admin-content">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}