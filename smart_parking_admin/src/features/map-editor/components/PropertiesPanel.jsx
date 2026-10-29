
export default function PropertiesPanel({
  selectedObject,
  onChange,
}) {
  if (!selectedObject) {
    return (
      <aside className="map-properties">
        <h3>Thuộc tính</h3>
        <p className="property-empty">
          Chọn một đối tượng trên bản đồ để chỉnh sửa.
        </p>
      </aside>
    );
  }

  const obj = selectedObject;

  function changeNumber(field, value) {
    if (value === "") return;

    const number = Number(value);
    if (!Number.isInteger(number)) return;

    onChange(obj.id, { [field]: number });
  }

  return (
    <aside className="map-properties">
      <h3>Thuộc tính đối tượng</h3>

      <label>
        Loại đối tượng
        <input value={obj.type} disabled />
      </label>

      <label>
        Tên hiển thị
        <input
          value={obj.label}
          onChange={(e) =>
            onChange(obj.id, { label: e.target.value })
          }
        />
      </label>

      <div className="property-grid">
        {["x", "y", "width", "height"].map((field) => (
          <label key={field}>
            {field.toUpperCase()}
            <input
              type="number"
              min={field === "width" || field === "height" ? 1 : 0}
              value={obj[field]}
              onChange={(e) =>
                changeNumber(field, e.target.value)
              }
            />
          </label>
        ))}
      </div>

      <div className="property-info">
        Bạn có thể chỉnh kích thước trực tiếp bằng cách kéo
        các điểm ở góc hoặc cạnh của đối tượng trên bản đồ.
      </div>
    </aside>
  );
}
