
export function roadKey(x, y) {
    return `${x},${y}`;
}

// Kiểm tra một ô lưới có nằm trong đối tượng hay không
export function isCellBlocked(x, y, objects) {
    return objects.some((obj) => {
        return (
            x >= obj.x &&
            x < obj.x + obj.width &&
            y >= obj.y &&
            y < obj.y + obj.height
        );
    });
}

// Tạo vùng đường từ một điểm chuột
export function getBrushCells(
    x,
    y,
    brushWidth,
    mapSize,
    objects
) {
    const cells = [];

    const offset = Math.floor(brushWidth / 2);

    for (let dy = 0; dy < brushWidth; dy++) {
        for (let dx = 0; dx < brushWidth; dx++) {
            const cellX = x + dx - offset;
            const cellY = y + dy - offset;

            // Không vượt bản đồ
            if (
                cellX < 0 ||
                cellY < 0 ||
                cellX >= mapSize.columns ||
                cellY >= mapSize.rows
            ) {
                continue;
            }

            // Không tô vào ô đỗ, cổng, dốc
            if (isCellBlocked(cellX, cellY, objects)) {
                continue;
            }

            cells.push({
                x: cellX,
                y: cellY,
            });
        }
    }

    return cells;
}

// Lấy các ô nằm giữa hai điểm kéo chuột
// Tránh bị đứt đường khi rê chuột nhanh
export function getCellsBetween(from, to) {
    const cells = [];

    const dx = to.x - from.x;
    const dy = to.y - from.y;

    const steps = Math.max(Math.abs(dx), Math.abs(dy));

    if (steps === 0) {
        return [to];
    }

    for (let i = 0; i <= steps; i++) {
        cells.push({
            x: Math.round(from.x + (dx * i) / steps),
            y: Math.round(from.y + (dy * i) / steps),
        });
    }

    return cells;
}
