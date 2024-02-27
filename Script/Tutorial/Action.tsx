import { BodyMoveType, cycle, Ease, Node, once, Opacity, sleep, Spine, thread, tolua, TypeName, Vec2 } from 'dora';
import { Unit, UnitAction, Data, BulletDef, Face, Bullet, TargetAllow, Relation } from 'Platformer'
import { React, toNode } from 'dora-x';
import * as Rectangle from 'UI/View/Shape/Rectangle';

export default function(this: void) {
	UnitAction.add("bmove", {
		priority: 1,
		reaction: 2.0,
		recovery: 0.2,
		available: (owner) => owner.onSurface,
		create: (owner) => {
			const playable = owner.playable;
			playable.play("bmove", true);
			return (owner, action) => {
				const {elapsedTime, recovery} = action;
				const move = owner.unitDef.move as number;
				let moveSpeed = 1.0;
				if (elapsedTime < recovery) {
					moveSpeed = math.min(elapsedTime / recovery, 1.0);
				}
				owner.velocityX = moveSpeed * (owner.faceRight ? -move : move) * 0.5;
				return !owner.onSurface;
			}
		}
	});

	UnitAction.add("fmove", {
		priority: 1,
		reaction: 2.0,
		recovery: 0.2,
		available: (owner) => owner.onSurface,
		create: (owner) => {
			const playable = owner.playable;
			playable.play("fmove", true);
			return (owner, action) => {
				const {elapsedTime, recovery} = action;
				const move = owner.unitDef.move as number;
				let moveSpeed = 1.0;
				if (elapsedTime < recovery) {
					moveSpeed = math.min(elapsedTime / recovery, 1.0);
				}
				owner.velocityX = moveSpeed * (owner.faceRight ? move : -move);
				return !owner.onSurface;
			};
		}
	});

	UnitAction.add("prepare", {
		priority: 1,
		reaction: 2.0,
		recovery: 0.2,
		available: (owner) => owner.onSurface,
		create: (owner) => {
			const playable = owner.playable;
			switch (playable.lastCompleted) {
				case "pistol":
				case "hit":
					playable.recovery = 0.0;
					break
			}
			playable.play("prepare", true);
			return () => !owner.onSurface;
		}
	});

	UnitAction.add("idle", {
		priority: 1,
		reaction: 2.0,
		recovery: 0.2,
		create: (owner) => {
			const playable = owner.playable;
			playable.play("idle", true);
			const playIdleSpecial = coroutine.create(() => {
				while (true) {
					sleep(3);
					sleep(playable.play("idle1"));
					playable.play("idle", true);
				}
			});
			owner.data.playIdleSpecial = playIdleSpecial;
			return () => {
				coroutine.resume(playIdleSpecial);
				return !owner.onSurface;
			};
		}
	});

	UnitAction.add("laser", {
		priority: 3,
		reaction: 3,
		recovery: 0.2,
		queued: true,
		create: (owner) => once(() => {
			owner.playable.slot("attack").set(() => {
				const bulletDef = BulletDef();
				bulletDef.lifeTime = 10;
				bulletDef.damageRadius = 0;
				bulletDef.highSpeedFix = true;
				bulletDef.gravity = Vec2.zero;
				bulletDef.face = Face(() => {
					return Rectangle({
						width: 10,
						height: 10,
						borderColor: 0xffff0088,
						fillColor: 0x66ff0088
					});
				});
				bulletDef.setAsCircle(10);
				bulletDef.setVelocity(0, 5000);
				const bullet = Bullet(bulletDef, owner);
				const targetAllow = TargetAllow();
				targetAllow.allow(Relation.Enemy, true);
				targetAllow.terrainAllowed = true;
				bullet.angle = 0
				bullet.targetAllow = targetAllow.toValue();
				bullet.slot("HitTarget", (bullet: Bullet.Type, target: Unit.Type, pos: Vec2.Type) => {
					const entity = target.entity as unknown as {hp: number, ap: number};
					target.data.hitFromRight = bullet.velocityX < 0;
					entity.ap -= 100;
					bullet.hitStop = true;
				});
				bullet.addTo(owner.world, owner.order);
				const pistol = owner.playable.getSlot("pistol");
				if (pistol) {
					const worldPos = pistol.convertToWorldSpace(Vec2(300, 0));
					const pos = owner.parent.convertToNodeSpace(worldPos);
					bullet.position = pos;
				}
			});
			sleep(owner.playable.play("pistol"));
			return true;
		})
	});

	UnitAction.add("kinetic", {
		priority: 3,
		reaction: 3,
		recovery: 0.2,
		queued: true,
		create: (owner) => once(() => {
			owner.playable.slot("attack").set(() => {
				const aimAngle = (owner.data.aimAngle ?? 0)  as number;
				const bulletDef = BulletDef();
				bulletDef.lifeTime = 10;
				bulletDef.damageRadius = 0;
				bulletDef.highSpeedFix = true;
				bulletDef.gravity = Vec2.zero;
				bulletDef.face = Face(() => {
					const spine = Spine("Spine/kineticgun");
					if (spine) {
						const node = Node();
						node.addChild(spine);
						spine.angle = owner.faceRight ? aimAngle : 180-aimAngle;
						spine.scaleX = 0.5;
						spine.scaleY = 0.5;
						spine.look = "PTbullet";
						return node;
					}
					return Node();
				});
				bulletDef.setAsCircle(10);
				bulletDef.setVelocity(-aimAngle, 5000);
				const bullet = Bullet(bulletDef, owner);
				const targetAllow = TargetAllow();
				targetAllow.allow(Relation.Enemy, true);
				targetAllow.terrainAllowed = true;
				bullet.targetAllow = targetAllow.toValue();
				bullet.slot("HitTarget", (bullet: Bullet.Type, target: Unit.Type, pos: Vec2.Type) => {
					const entity = target.entity as unknown as {hp: number, ap: number};
					target.data.hitFromRight = bullet.velocityX < 0;
					entity.hp -= 1;
					bullet.hitStop = true;
				});
				bullet.addTo(owner.world, owner.order);
				const pistol = owner.playable.getSlot("pistol");
				if (pistol) {
					let worldPos = pistol.convertToWorldSpace(Vec2(300, 0));
					let pos = owner.parent.convertToNodeSpace(worldPos);
					bullet.position = pos;
					worldPos = pistol.convertToWorldSpace(Vec2.zero);
					pos = owner.parent.convertToNodeSpace(worldPos);
					const casing = toNode(
						<body
							type={BodyMoveType.Dynamic}
							x={pos.x} y={pos.y} world={owner.world}
							group={Data.groupHide} linearAcceleration={Vec2(0, -9.8)}
							velocityX={math.random() * (owner.faceRight ? -100 : 100)}
							velocityY={math.random() * 300}
							angle={math.random() * aimAngle}
						>
							<rect-fixture width={20} height={10} density={26} friction={0.4} restitution={0.4}/>
							<spine file='Spine/kineticgun' look='PTcasing' scaleX={0.5} scaleY={0.5}/>
						</body>
					);
					if (casing) {
						casing.schedule(once(() => {
							sleep(10);
							sleep(casing.perform(Opacity(0.5, 1, 0)));
							casing.removeFromParent();
						}))
						casing.addTo(owner.world, owner.order);
					}
				}
				const playable = tolua.cast(owner.playable, TypeName.Spine);
				if (playable) {
					playable.schedule(once(() => {
						sleep(0.2);
						cycle(0.2, (time) => {
							const angle = -(1 - Ease.func(Ease.OutSine, time)) * (aimAngle as number);
							owner.data.aimAngle = angle;
							playable.setBoneRotation("aim", (angle as number));
						});
					}));
				}
			});
			const aim = owner.getChildByTag("aim");
			const playable = tolua.cast(owner.playable, TypeName.Spine);
			if (aim && playable) {
				const angle = aim.angle;
				playable.schedule(once(() => {
					const fix = owner.faceRight ? 1 : -1;
					cycle(0.2, (time) => {
						const aimAngle = -Ease.func(Ease.OutSine, time) * fix * angle;
						owner.data.aimAngle = -aimAngle;
						playable.setBoneRotation("aim", aimAngle);
					});
				}));
			}
			sleep(owner.playable.play("pistol"));
			return true;
		}),
		stop: (owner) => {
			const aimAngle = owner.data.aimAngle;
			if (aimAngle) {
				const playable = tolua.cast(owner.playable, TypeName.Spine);
				if (playable) {
					playable.schedule(once(() => {
						cycle(0.2, (time) => {
							playable.setBoneRotation("aim", -(1 - Ease.func(Ease.OutSine, time)) * (aimAngle as number));
						});
					}));
				}
			}
		}
	});

	UnitAction.add("hit", {
		priority: 99,
		reaction: 3,
		recovery: 0.2,
		create: (owner) => once(() => {
			sleep(owner.playable.play("hit"));
			return true;
		})
	});

	UnitAction.add("dizzy", {
		priority: 99,
		reaction: 3,
		recovery: 0.2,
		create: (owner) => {
			owner.playable.play("dizzy", true);
			return () => false;
		},
	});

	UnitAction.add("lose", {
		priority: 99,
		reaction: 3,
		recovery: 0.2,
		create: (owner) => once(() => {
			const time = owner.playable.play("lose");
			sleep(time - 0.05);
			owner.playable.speed = 0;
			return true;
		})
	});

	UnitAction.add("blow", {
		reaction: 3,
		recovery: 0.2,
		priority: 3,
		queued: true,
		create: (owner) => {
			owner.playable.slot("attack").set(() => {
				const senser = owner.getSensorByTag(Unit.AttackSensorTag);
				senser.sensedBodies.each((item) => {
					const unit = tolua.cast(item, TypeName.Unit);
					if (unit && Data.isEnemy(unit.group, owner.group) && (unit.x >= owner.x == owner.faceRight)) {
						unit.applyLinearImpulse(Vec2(unit.x < owner.x ? -500 : 500, 0), Vec2.zero);
						unit.start("cancal");
						if (unit.x < owner.x && !unit.faceRight) {
							unit.start("turn");
						}
						unit.start("hit");
					}
					return false;
				})
			});
			return once(() => {
				sleep(owner.playable.play("blow"));
				return true;
			})
		}
	});

	UnitAction.add("fallOff", {
		priority: 2,
		reaction: -1,
		recovery: 0.3,
		queued: true,
		available: (owner) => !owner.onSurface,
		create: (owner) => {
			const playable = owner.playable;
			if (playable.current != "jumping") {
				playable.play("jumping", true);
			}
			return once(() => {
				while (true) {
					if (owner.onSurface) {
						sleep(playable.play("landing", false));
						coroutine.yield(true);
					} else {
						coroutine.yield(false);
					}
				}
			});
		}
	});
};
