
import { NavLink } from "react-router-dom";
import {
    LayoutDashboard,
    Warehouse,
    Map,
    PencilRuler,
    CarFront,
    History,
    ChartColumn,
    Settings,
    ParkingSquare,
} from "lucide-react";

const menuItems = [
    {
        title: "Tổng quan",
        path: "/",
        icon: LayoutDashboard,
    },
    {
        title: "Thiết kế bản đồ",
        path: "/map-editor",
        icon: PencilRuler,
    },
];

export default function Sidebar() {
    return (
        <aside className="sidebar">
            <div className="sidebar-brand">
                <div>
                    <h2>SmartParking</h2>
                    <span>ADMIN SYSTEM</span>
                </div>
            </div>


            <nav className="sidebar-nav">
                {menuItems.map((item) => {
                    const Icon = item.icon;

                    return (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            end={item.path === "/"}
                            className={({ isActive }) =>
                                `sidebar-link ${isActive ? "active" : ""}`
                            }
                        >
                            <Icon size={19} />
                            <span>{item.title}</span>
                        </NavLink>
                    );
                })}
            </nav>

        </aside>
    );
}
