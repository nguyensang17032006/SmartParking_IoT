import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  LogIn,
  ParkingSquare,
  ShieldCheck,
} from "lucide-react";
import toast from "react-hot-toast";

import { useAuth } from "../contexts/AuthContext";
import "../styles/auth.css";

export default function Login() {
  const [email, setEmail] = useState("titisang1703@gmail.com");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const { login, user, isAdmin, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || "/";

  // Nếu đã đăng nhập với quyền Admin, tự động chuyển vào trang quản trị
  useEffect(() => {
    if (!loading && user && isAdmin) {
      navigate(from, { replace: true });
    }
  }, [user, isAdmin, loading, navigate, from]);

  async function handleSubmit(e) {
    e.preventDefault();

    if (!email.trim() || !password) {
      toast.error("Vui lòng nhập đầy đủ Email và Mật khẩu!");
      return;
    }

    setSubmitting(true);
    try {
      await login(email.trim(), password);
      toast.success("Đăng nhập quyền Quản trị viên thành công!");
      navigate(from, { replace: true });
    } catch (error) {
      console.error("Lỗi đăng nhập:", error);
      toast.error(error.message || "Đăng nhập thất bại. Vui lòng kiểm tra lại!");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <div className="auth-brand-icon">
            <ParkingSquare size={32} />
          </div>
          <h1>SmartParking Admin</h1>
          <p>Đăng nhập tài khoản Quản trị viên để quản lý hệ thống</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <div className="auth-field">
            <label htmlFor="auth-email">Email quản trị</label>
            <div className="auth-input-wrapper">
              <Mail size={18} className="auth-input-icon" />
              <input
                id="auth-email"
                type="email"
                className="auth-input"
                placeholder="admin@smartparking.com"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
          </div>

          <div className="auth-field">
            <label htmlFor="auth-password">Mật khẩu</label>
            <div className="auth-input-wrapper">
              <Lock size={18} className="auth-input-icon" />
              <input
                id="auth-password"
                type={showPassword ? "text" : "password"}
                className="auth-input"
                placeholder="••••••••"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <button
                type="button"
                className="auth-input-btn"
                onClick={() => setShowPassword(!showPassword)}
                title={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            className="auth-btn-submit"
            disabled={submitting}
          >
            <LogIn size={18} />
            {submitting ? "Đang xác thực quyền..." : "Đăng nhập hệ thống"}
          </button>
        </form>

        <div className="auth-footer-notice">
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "6px",
              marginBottom: "4px",
              color: "#166534",
              fontWeight: "600",
            }}
          >
            <ShieldCheck size={16} /> Phân quyền bảo mật RLS
          </div>
          Chỉ các tài khoản có <strong>role = 'admin'</strong> trong bảng{" "}
          <code>profiles</code> mới có quyền truy cập và thao tác thêm/sửa/xóa
          dữ liệu trên hệ thống.
        </div>
      </div>
    </div>
  );
}

