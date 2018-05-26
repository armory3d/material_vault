package arm;

import iron.Trait;
import iron.system.Input;
import iron.object.Object;
import iron.object.Transform;
import iron.system.Audio;
import iron.system.Time;
import armory.trait.physics.RigidBody;

@:keep
class GunController extends Trait {

#if (!arm_physics)
	public function new() { super(); }
#else

	@prop
	public var fireFreq = 0.2;

	var projectileRef:String;
	var firePoint:Transform;
	var fireStrength = 25;
	var lastFire = 0.0;
	var soundFire0:kha.Sound = null;
	var soundFire1:kha.Sound = null;

	public function new(projectileRef:String, firePointRef:String) {
		super();

		this.projectileRef = projectileRef;
		
		notifyOnInit(function() {
			firePoint = object.getChild(firePointRef).transform;

			iron.data.Data.getSound("fire0.wav", function(sound:kha.Sound) {
				soundFire0 = sound;
			});

			iron.data.Data.getSound("fire1.wav", function(sound:kha.Sound) {
				soundFire1 = sound;
			});

			// TODO: Bug - 'parent to bone' does not produce correct transform..
			// Offset gun manually for now to fit it in hand :(
			object.transform.loc.x -= 22.0;
			object.transform.loc.y += 30.0;
			object.transform.loc.z += 1.0;
			object.transform.buildMatrix();
		});
		
		notifyOnUpdate(function() {
			var mouse = Input.getMouse();
			lastFire += Time.delta;
			if ((mouse.down("left") && lastFire > fireFreq) || mouse.started("left")) {
				shoot();
				Audio.play(Std.random(3) == 0 ? soundFire1 : soundFire0);
				lastFire = 0.0;
			}
		});
	}

	function shoot() {
		// Spawn projectile
		iron.Scene.active.spawnObject(projectileRef, null, function(o:Object) {
			o.transform.loc.x = firePoint.worldx();
			o.transform.loc.y = firePoint.worldy();
			o.transform.loc.z = firePoint.worldz();
			o.transform.buildMatrix();
			// Apply force
			var rb:RigidBody = o.getTrait(RigidBody);
			rb.syncTransform();
			var look = object.transform.look().normalize();
			rb.setLinearVelocity(look.x * fireStrength, look.y * fireStrength, look.z * fireStrength);
			// Remove projectile after a period of time
			kha.Scheduler.addTimeTask(function() {
				o.remove();
			}, 10);
		});
	}
#end
}
