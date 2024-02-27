// @preview-file off
import { React, toNode, useRef } from 'dora-x';
import { Color, Color3, DrawNode, Vec2 } from 'dora';

interface BarProps {
	y: number;
	width: number;
	height: number;
	color3: number;
	percentage?: number;
	ref?: JSX.Ref<DrawNode.Type>;
}

function Bar(props: BarProps) {
	const {width, height, y} = props;
	const hw = width / 2;
	const percentage = props.percentage ?? 1.0;
	return (
		<>
			<polygon-shape verts={[
				Vec2(-hw, y),
				Vec2(-hw, height + y),
				Vec2(hw, height + y),
				Vec2(hw, y),
			]} fillColor={Color(Color3(props.color3), 127).toARGB()}/>
			<draw-node scaleX={percentage} x={-hw} ref={props.ref} color3={props.color3}>
				<polygon-shape verts={[
					Vec2(0, y),
					Vec2(0, height + y),
					Vec2(width, height + y),
					Vec2(width, y),
				]} fillColor={0xffffffff}/>
			</draw-node>
		</>
	);
}

interface StatusBarProps {
	width: number;
	height: number;
	bars: {
		color3: number,
		percentage?: number,
		ref?: JSX.Ref<DrawNode.Type>
	}[];
}

function StatusBar(props: StatusBarProps) {
	const {width, height} = props;
	return (
		<draw-node>
			{
				props.bars.map((bar, i) =>
					<Bar
						ref={bar.ref}
						y={i * height}
						width={width} height={height}
						color3={bar.color3}
						percentage={bar.percentage}
					/>
				)
			}
		</draw-node>
	);
};

export default function StatusBarNode(this: void, hp: number, ap: number, hpColor3: number) {
	const hpBar = useRef<DrawNode.Type>();
	const apBar = useRef<DrawNode.Type>();
	const node = toNode(
		<StatusBar width={100} height={10} bars={[
			{color3: 0x8dbef3, percentage: ap, ref: apBar},
			{color3: hpColor3, percentage: hp, ref: hpBar}
		]}/>
	);
	return $multi(node, hpBar.current, apBar.current);
}
