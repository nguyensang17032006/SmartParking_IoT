import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";

export default function ProtectedRoute() {
  const { user, isAdmin, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "100vh",
          background: "#f5f7fb",
          gap: "14px",
          color: "#475569",
          fontSize: "14px",
          fontWeight: "600",
        }}
      >
        <div
          style={{
            width: "36px",
            height: "36px",
            border: "3px solid #e2e8f0",
            borderTopColor: "#13b99a",
            borderRadius: "50%",
            animation: "spin 0.8s linear infinite",
          }}
        />
        <span>Đang kiểm tra quyền quản trị viên...</span>
        <style>{`
          @keyframes spin {
            to { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  if (!user || !isAdmin) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <Outlet />;
}

