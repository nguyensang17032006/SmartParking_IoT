import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Plus, Pencil, Trash2, Map, X, CheckCircle2, XCircle } from "lucide-react";
import toast from "react-hot-toast";

import {
  getCampuses,
  getParkingLots,
  createParkingLot,
  updateParkingLot,
  deleteParkingLot,
} from "../features/map-editor/service/mapService";

import "../styles/management.css";

export default function ParkingLots() {
  const [campuses, setCampuses] = useState([]);
  const [selectedCampusId, setSelectedCampusId] = useState("");
  const [lots, setLots] = useState([]);
  const [loading, setLoading] = useState(false);

  // Modal State
  const [isOpenModal, setIsOpenModal] = useState(false);
  const [editingLot, setEditingLot] = useState(null);
  const [formData, setFormData] = useState({
    campus_id: "",
    name: "",
    status: "active",
  });
  const [submitting, setSubmitting] = useState(false);

  async function fetchInitialData() {
    try {
      const campusData = await getCampuses();
      setCampuses(campusData);
    } catch (error) {
      console.error("Lỗi tải cơ sở:", error);
    }
  }

  async function fetchLots() {
    setLoading(true);
    try {
      const data = await getParkingLots(selectedCampusId || null);
      setLots(data);
    } catch (error) {
      console.error("Lỗi tải bãi xe:", error);
      toast.error("Không thể tải danh sách bãi xe: " + error.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchInitialData();
  }, []);

  useEffect(() => {
    fetchLots();
  }, [selectedCampusId]);

  function handleOpenAdd() {
    setEditingLot(null);
    setFormData({
      campus_id: selectedCampusId || (campuses[0]?.id ?? ""),
      name: "",
      status: "active",
    });
    setIsOpenModal(true);
  }

  function handleOpenEdit(lot) {
    setEditingLot(lot);
    setFormData({
      campus_id: lot.campus_id || "",
      name: lot.name || "",
      status: lot.status || "active",
    });
    setIsOpenModal(true);
  }

  function handleCloseModal() {
    setIsOpenModal(false);
    setEditingLot(null);
  }

  async function handleSubmit(e) {
    e.preventDefault();

    if (!formData.campus_id) {
      toast.error("Vui lòng chọn cơ sở!");
      return;
    }

    if (!formData.name.trim()) {
      toast.error("Vui lòng nhập tên bãi xe!");
      return;
    }

    setSubmitting(true);
    try {
      if (editingLot) {
        await updateParkingLot(editingLot.id, {
          campus_id: formData.campus_id,
          name: formData.name.trim(),
          status: formData.status,
        });
        toast.success("Cập nhật bãi xe thành công!");
      } else {
        await createParkingLot({
          campus_id: formData.campus_id,
          name: formData.name.trim(),
          status: formData.status,
        });
        toast.success("Thêm bãi xe mới thành công!");
      }
      handleCloseModal();
      fetchLots();
    } catch (error) {
      console.error("Lỗi lưu bãi xe:", error);
      toast.error("Thao tác thất bại: " + error.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(lot) {
    const confirmed = window.confirm(
      `Bạn có chắc chắn muốn xóa bãi xe "${lot.name}"?\n\nToàn bộ sơ đồ và các tầng thuộc bãi xe này sẽ bị xóa!`
    );

    if (!confirmed) return;

    try {
      await deleteParkingLot(lot.id);
      toast.success(`Đã xóa bãi xe "${lot.name}"!`);
      fetchLots();
    } catch (error) {
      console.error("Lỗi xóa bãi xe:", error);
      toast.error("Không thể xóa bãi xe: " + error.message);
    }
  }

  // Helper để lấy tên cơ sở
  function getCampusName(campusId) {
    const c = campuses.find((item) => item.id === campusId);
    return c ? `${c.code} - ${c.name}` : "—";
  }

  return (
    <div className="management-page">
      <div className="management-header">
        <div>
          <h2>Quản lý bãi xe (Parking Lots)</h2>
          <p>Danh sách các khu vực / bãi đỗ xe thuộc từng cơ sở.</p>
        </div>
        <div className="management-actions">
          <button className="btn-primary" onClick={handleOpenAdd}>
            <Plus size={16} />
            Thêm bãi xe mới
          </button>
        </div>
      </div>

      {/* Lọc theo cơ sở */}
      <div className="management-filter-bar">
        <label htmlFor="campus-filter">Lọc theo cơ sở:</label>
        <select
          id="campus-filter"
          value={selectedCampusId}
          onChange={(e) => setSelectedCampusId(e.target.value)}
        >
          <option value="">-- Tất cả cơ sở --</option>
          {campuses.map((campus) => (
            <option key={campus.id} value={campus.id}>
              {campus.code} - {campus.name}
            </option>
          ))}
        </select>
      </div>

      <div className="management-table-container">
        <table className="management-table">
          <thead>
            <tr>
              <th style={{ width: "80px" }}>STT</th>
              <th>Tên bãi xe</th>
              <th>Thuộc cơ sở</th>
              <th style={{ width: "160px" }}>Trạng thái</th>
              <th style={{ width: "150px", textAlign: "center" }}>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="5" className="table-empty">
                  Đang tải danh sách bãi xe...
                </td>
              </tr>
            ) : lots.length === 0 ? (
              <tr>
                <td colSpan="5" className="table-empty">
                  Chưa có bãi xe nào. Hãy bấm "Thêm bãi xe mới" để tạo!
                </td>
              </tr>
            ) : (
              lots.map((lot, index) => (
                <tr key={lot.id}>
                  <td>{index + 1}</td>
                  <td>
                    <strong>{lot.name}</strong>
                  </td>
                  <td>{getCampusName(lot.campus_id)}</td>
                  <td>
                    <span
                      className={`status-badge ${
                        lot.status === "inactive" ? "inactive" : "active"
                      }`}
                    >
                      {lot.status === "inactive" ? (
                        <>
                          <XCircle size={13} />
                          Tạm đóng
                        </>
                      ) : (
                        <>
                          <CheckCircle2 size={13} />
                          Đang hoạt động
                        </>
                      )}
                    </span>
                  </td>
                  <td style={{ textAlign: "center" }}>
                    <div className="table-actions" style={{ justifyContent: "center" }}>
                      <Link
                        to="/map-editor"
                        className="btn-icon link"
                        title="Vẽ sơ đồ bãi xe"
                      >
                        <Map size={15} />
                      </Link>
                      <button
                        className="btn-icon edit"
                        title="Chỉnh sửa"
                        onClick={() => handleOpenEdit(lot)}
                      >
                        <Pencil size={15} />
                      </button>
                      <button
                        className="btn-icon delete"
                        title="Xóa"
                        onClick={() => handleDelete(lot)}
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

      {/* Modal Thêm / Sửa bãi xe */}
      {isOpenModal && (
        <div className="modal-overlay" onClick={handleCloseModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editingLot ? "Chỉnh sửa bãi xe" : "Thêm bãi xe mới"}</h3>
              <button className="modal-close" onClick={handleCloseModal}>
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label>Thuộc cơ sở *</label>
                  <select
                    required
                    value={formData.campus_id}
                    onChange={(e) =>
                      setFormData({ ...formData, campus_id: e.target.value })
                    }
                  >
                    <option value="">-- Chọn cơ sở --</option>
                    {campuses.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.code} - {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Tên bãi xe *</label>
                  <input
                    type="text"
                    required
                    placeholder="Ví dụ: Bãi xe khu A, Bãi hầm B1..."
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                  />
                </div>

                <div className="form-group">
                  <label>Trạng thái</label>
                  <select
                    value={formData.status}
                    onChange={(e) =>
                      setFormData({ ...formData, status: e.target.value })
                    }
                  >
                    <option value="active">Đang hoạt động</option>
                    <option value="inactive">Tạm đóng</option>
                  </select>
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
                    : editingLot
                    ? "Cập nhật"
                    : "Tạo bãi xe"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

