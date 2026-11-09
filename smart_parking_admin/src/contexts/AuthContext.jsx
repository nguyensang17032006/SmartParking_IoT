import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "../lib/supabaseClient";

const AuthContext = createContext({
  user: null,
  profile: null,
  isAdmin: false,
  loading: true,
  login: async () => {},
  logout: async () => {},
});

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  async function fetchProfile(userId) {
    try {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, full_name, role")
        .eq("id", userId)
        .maybeSingle();

      if (error) {
        console.error("Lỗi lấy thông tin profile:", error);
        return null;
      }

      return data;
    } catch (err) {
      console.error("Lỗi fetchProfile:", err);
      return null;
    }
  }

  useEffect(() => {
    let mounted = true;

    async function initAuth() {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();

        if (session?.user && mounted) {
          const prof = await fetchProfile(session.user.id);

          if (prof && prof.role === "admin") {
            setUser(session.user);
            setProfile(prof);
            setIsAdmin(true);
          } else {
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            setIsAdmin(false);
          }
        }
      } catch (err) {
        console.error("Lỗi khởi tạo phiên đăng nhập:", err);
      } finally {
        if (mounted) setLoading(false);
      }
    }

    initAuth();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "SIGNED_IN" && session?.user) {
        const prof = await fetchProfile(session.user.id);
        if (prof && prof.role === "admin") {
          setUser(session.user);
          setProfile(prof);
          setIsAdmin(true);
        } else {
          await supabase.auth.signOut();
          setUser(null);
          setProfile(null);
          setIsAdmin(false);
        }
      } else if (event === "SIGNED_OUT") {
        setUser(null);
        setProfile(null);
        setIsAdmin(false);
      }
    });

    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    const prof = await fetchProfile(data.user.id);

    if (!prof || prof.role !== "admin") {
      await supabase.auth.signOut();
      throw new Error(
        "Tài khoản của bạn không có quyền Quản trị viên (Admin) để truy cập hệ thống!"
      );
    }

    setUser(data.user);
    setProfile(prof);
    setIsAdmin(true);
    return { user: data.user, profile: prof };
  }

  async function logout() {
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
    setIsAdmin(false);
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        isAdmin,
        loading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
