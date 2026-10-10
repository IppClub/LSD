"""Original mechanical hatch sound: latch, rotating geared motor, final metal stop."""
import math,random,struct,wave
from pathlib import Path
rate=48000;duration=2.8;rng=random.Random(217);data=bytearray();low=0
for n in range(round(rate*duration)):
 t=n/rate;noise=rng.uniform(-1,1);low=.92*low+.08*noise
 motor=0
 if .22<t<2.42:
  u=(t-.22)/2.2;env=math.sin(math.pi*u)**.45
  motor=env*(.075*math.sin(2*math.pi*(76*t+11*t*t))+.035*math.sin(2*math.pi*243*t)+.11*low+.018*noise)*(1+.2*math.sin(2*math.pi*17*t))
 metal=0
 for start,gain,decay in [(0,.22,12),(.14,.11,18),(2.4,.25,10)]:
  u=t-start
  if u>=0:metal+=gain*math.exp(-decay*u)*sum(math.sin(2*math.pi*f*u+p) for f,p in [(317,0),(827,.2),(1483,.5),(2911,.4)])/4
 v=(motor+metal)*min(1,t/.003,(duration-t)/.05)
 data+=struct.pack('<h',round(max(-.9,min(.9,v))*32767))
p=Path(__file__).resolve().parents[1]/'Sound/control-pod-hatch.wav'
with wave.open(str(p),'wb')as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(data)
print(p)
