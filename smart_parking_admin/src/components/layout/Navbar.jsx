
import { useLocation } from "react-router-dom";
import { Bell, CircleUserRound } from "lucide-react";

const pageTitles = {
  "/": "Tổng quan hệ thống",
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

  const title =
    pageTitles[location.pathname] ??
    (location.pathname.startsWith("/parking-lots/")
      ? "Chi tiết bãi xe"
      : "SmartParking Admin");

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
            <strong>Administrator</strong>
            <span>Quản trị viên</span>
          </div>
        </div>
      </div>
    </header>
  );
}
