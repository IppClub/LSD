"""Deterministic original procedural water/bird ambience, no external recordings."""
from pathlib import Path
import wave,math,random,struct
rng=random.Random(20412);rate=24000;seconds=24;low=0.;phase=0.;data=bytearray()
birds=[(2.4,.34,2200),(2.92,.25,2650),(7.2,.42,1900),(7.85,.28,2400),(13.1,.35,2100),(13.6,.3,2800),(19.4,.42,1850),(20.02,.3,2450)]
for n in range(rate*seconds):
 t=n/rate;noise=rng.uniform(-1,1);low=low*.985+noise*.015
 water=(noise*.010+low*.16)*(1+.15*math.sin(t*2*math.pi*.21))
 chirp=0
 for start,length,f in birds:
  u=(t-start)/length
  if 0<=u<1:
   chirp+=.038*math.sin(math.pi*u)**2*math.sin(2*math.pi*(f*(t-start)+350*(t-start)**2/length)+.5*math.sin(u*math.pi*8))
 edge=min(1,t/.7,(seconds-t)/.7);v=max(-.12,min(.12,(water+chirp)*edge))
 data+=struct.pack('<h',round(v*32767))
p=Path(__file__).resolve().parents[1]/'Sound/valley-water-birds.wav'
with wave.open(str(p),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(data)
print('Original quiet 24-second ambience generated:',p)
