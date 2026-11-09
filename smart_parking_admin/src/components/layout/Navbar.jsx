import { useLocation } from "react-router-dom";
import { Bell, CircleUserRound, LogOut } from "lucide-react";
import toast from "react-hot-toast";

import { useAuth } from "../../contexts/AuthContext";

const pageTitles = {
  "/": "Tổng quan hệ thống",
  "/campuses": "Quản lý cơ sở",
  "/parking-lots": "Quản lý bãi xe",
  "/map-editor": "Thiết kế bản đồ",
  "/map-monitoring": "Giám sát bản đồ",
  "/vehicles": "Quản lý xe vào / ra",
  "/history": "Lịch sử hoạt động",
  "/statistics": "Thống kê và báo cáo",
  "/settings": "Cài đặt",
};

export default function Navbar() {
  const location = useLocation();
  const { user, profile, logout } = useAuth();

  const title =
    pageTitles[location.pathname] ??
    (location.pathname.startsWith("/parking-lots/")
      ? "Chi tiết bãi xe"
      : "SmartParking Admin");

  async function handleLogout() {
    try {
      await logout();
      toast.success("Đã đăng xuất khỏi hệ thống!");
    } catch (err) {
      console.error("Lỗi đăng xuất:", err);
      toast.error("Đăng xuất thất bại: " + err.message);
    }
  }

  const displayName = profile?.full_name || user?.email?.split("@")[0] || "Administrator";
  const displayRole = user?.email || "Quản trị viên";

  return (
    <header className="navbar">
      <div className="navbar-heading">
        <h1>{title}</h1>
        <p>Hệ thống quản lý bãi đỗ xe thông minh</p>
      </div>

      <div className="navbar-actions">
        <div className="navbar-icon" aria-label="Thông báo">
          <Bell size={20} />
        </div>

        <div className="admin-profile">
          <CircleUserRound size={32} />
          <div>
            <strong>{displayName}</strong>
            <span title={user?.email}>{displayRole}</span>
          </div>

          <button
            type="button"
            className="btn-icon delete"
            style={{ marginLeft: "8px", width: "34px", height: "34px" }}
            onClick={handleLogout}
            title="Đăng xuất khỏi hệ thống"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </header>
  );
}
