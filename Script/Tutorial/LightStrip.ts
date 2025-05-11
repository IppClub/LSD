// @preview-file off
import { Color, DrawNode, Node, Slot, Vec2 } from 'Dora';

export function LightStrip(this: void, startPoint: Vec2.Type, targetNode: Node.Type, color: number) {
	const node = DrawNode();
	node.position = startPoint;
	if (targetNode.parent) {
		node.addTo(targetNode.parent, targetNode.order);
	}
	let target: Node.Type | null = targetNode;
	targetNode.slot(Slot.Cleanup, () => {
		target = null;
	});
	targetNode.slot("StopStrip", () => {
		target = null;
	});
	let stopPoint = target.position;
	let current = 0;
	const step = 10;
	const stepTime = 0.02;
	const targetColor = Color(color);
	const startOpacity = targetColor.opacity;
	const verts = [
		Vec2.zero,
		Vec2.zero,
		Vec2.zero,
		Vec2.zero,
	];
	node.schedule((deltaTime) => {
		node.clear();
		if (target) {
			stopPoint = target.position;
		}
		const distance = math.min(1000, stopPoint.distance(startPoint));
		const angle = stopPoint.sub(startPoint).angle;
		node.angle = -angle + 90;
		let i = 0;
		let ended = true;
		for (let dist = 0; dist < distance; dist += step) {
			const start = step * i;
			const stop = math.min(start + step, distance);
			const duration = (i + 1) * stepTime;
			if (current < duration) {
				ended = false;
			}
			const alpha = 1.0 - (current / duration);
			if (alpha > 0) {
				targetColor.opacity = alpha * startOpacity;
				verts[0] = Vec2(-step / 2, start);
				verts[1] = Vec2(-step / 2, stop);
				verts[2] = Vec2(step / 2, stop);
				verts[3] = Vec2(step / 2, start);
				node.drawPolygon(verts, targetColor);
			}
			i++;
		}
		if (ended) {
			node.clear();
			node.removeFromParent();
			return true;
		}
		current += deltaTime;
		return false;
	});
}