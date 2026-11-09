import { useEffect, useState } from "react";
import { Plus, Pencil, Trash2, Building2, X } from "lucide-react";
import toast from "react-hot-toast";

import {
  getCampuses,
  createCampus,
  updateCampus,
  deleteCampus,
} from "../features/map-editor/service/mapService";

import "../styles/management.css";

export default function Campuses() {
  const [campuses, setCampuses] = useState([]);
  const [loading, setLoading] = useState(false);

  // Modal State
  const [isOpenModal, setIsOpenModal] = useState(false);
  const [editingCampus, setEditingCampus] = useState(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    address: "",
  });
  const [submitting, setSubmitting] = useState(false);

  async function fetchCampuses() {
    setLoading(true);
    try {
      const data = await getCampuses();
      setCampuses(data);
    } catch (error) {
      console.error("Lỗi tải cơ sở:", error);
      toast.error("Không thể tải danh sách cơ sở: " + error.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchCampuses();
  }, []);

  function handleOpenAdd() {
    setEditingCampus(null);
    setFormData({ code: "", name: "", address: "" });
    setIsOpenModal(true);
  }

  function handleOpenEdit(campus) {
    setEditingCampus(campus);
    setFormData({
      code: campus.code || "",
      name: campus.name || "",
      address: campus.address || "",
    });
    setIsOpenModal(true);
  }

  function handleCloseModal() {
    setIsOpenModal(false);
    setEditingCampus(null);
  }

  async function handleSubmit(e) {
    e.preventDefault();

    if (!formData.code.trim() || !formData.name.trim()) {
      toast.error("Vui lòng nhập mã và tên cơ sở!");
      return;
    }

    setSubmitting(true);
    try {
      if (editingCampus) {
        await updateCampus(editingCampus.id, {
          code: formData.code.trim(),
          name: formData.name.trim(),
          address: formData.address.trim(),
        });
        toast.success("Cập nhật cơ sở thành công!");
      } else {
        await createCampus({
          code: formData.code.trim(),
          name: formData.name.trim(),
          address: formData.address.trim(),
        });
        toast.success("Thêm cơ sở mới thành công!");
      }
      handleCloseModal();
      fetchCampuses();
    } catch (error) {
      console.error("Lỗi lưu cơ sở:", error);
      toast.error("Thao tác thất bại: " + error.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(campus) {
    const confirmed = window.confirm(
      `Bạn có chắc chắn muốn xóa cơ sở "${campus.name}" (${campus.code})?\n\nLưu ý: Các bãi xe thuộc cơ sở này có thể bị ảnh hưởng!`
    );

    if (!confirmed) return;

    try {
      await deleteCampus(campus.id);
      toast.success(`Đã xóa cơ sở "${campus.name}"!`);
      fetchCampuses();
    } catch (error) {
      console.error("Lỗi xóa cơ sở:", error);
      toast.error("Không thể xóa cơ sở: " + error.message);
    }
  }

  return (
    <div className="management-page">
      <div className="management-header">
        <div>
          <h2>Quản lý cơ sở (Campuses)</h2>
          <p>Danh sách các cơ sở, chi nhánh trường học / tòa nhà trong hệ thống.</p>
        </div>
        <div className="management-actions">
          <button className="btn-primary" onClick={handleOpenAdd}>
            <Plus size={16} />
            Thêm cơ sở mới
          </button>
        </div>
      </div>

      <div className="management-table-container">
        <table className="management-table">
          <thead>
            <tr>
              <th style={{ width: "80px" }}>STT</th>
              <th style={{ width: "160px" }}>Mã cơ sở</th>
              <th>Tên cơ sở</th>
              <th>Địa chỉ</th>
              <th style={{ width: "130px", textAlign: "center" }}>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="5" className="table-empty">
                  Đang tải danh sách cơ sở...
                </td>
              </tr>
            ) : campuses.length === 0 ? (
              <tr>
                <td colSpan="5" className="table-empty">
                  Chưa có cơ sở nào. Hãy bấm "Thêm cơ sở mới" để tạo!
                </td>
              </tr>
            ) : (
              campuses.map((campus, index) => (
                <tr key={campus.id}>
                  <td>{index + 1}</td>
                  <td>
                    <span className="code-badge">{campus.code}</span>
                  </td>
                  <td>
                    <strong>{campus.name}</strong>
                  </td>
                  <td>{campus.address || "—"}</td>
                  <td style={{ textAlign: "center" }}>
                    <div className="table-actions" style={{ justifyContent: "center" }}>
                      <button
                        className="btn-icon edit"
                        title="Chỉnh sửa"
                        onClick={() => handleOpenEdit(campus)}
                      >
                        <Pencil size={15} />
                      </button>
                      <button
                        className="btn-icon delete"
                        title="Xóa"
                        onClick={() => handleDelete(campus)}
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modal Thêm / Sửa cơ sở */}
      {isOpenModal && (
        <div className="modal-overlay" onClick={handleCloseModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editingCampus ? "Chỉnh sửa cơ sở" : "Thêm cơ sở mới"}</h3>
              <button className="modal-close" onClick={handleCloseModal}>
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label>Mã cơ sở *</label>
                  <input
                    type="text"
                    required
                    placeholder="Ví dụ: CS1, CS2, MAIN..."
                    value={formData.code}
                    onChange={(e) =>
                      setFormData({ ...formData, code: e.target.value })
                    }
                  />
                </div>

                <div className="form-group">
                  <label>Tên cơ sở *</label>
                  <input
                    type="text"
                    required
                    placeholder="Ví dụ: Cơ sở 1 - Quận 1..."
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                  />
                </div>

                <div className="form-group">
                  <label>Địa chỉ</label>
                  <input
                    type="text"
                    placeholder="Địa chỉ cụ thể..."
                    value={formData.address}
                    onChange={(e) =>
                      setFormData({ ...formData, address: e.target.value })
                    }
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={handleCloseModal}
                  disabled={submitting}
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={submitting}
                >
                  {submitting
                    ? "Đang lưu..."
                    : editingCampus
                    ? "Cập nhật"
                    : "Tạo cơ sở"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

