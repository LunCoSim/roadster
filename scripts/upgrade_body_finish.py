#!/usr/bin/env python3
"""Refine the cosmetic shell through the native document journal, never physics.

Original study geometry, not Tesla CAD. Requires the explicitly owned API port.
The dry plan is recorded before one generation-checked visual-component edit.
"""
import argparse, ast, collections, json, math, sys, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
from author_body_style import profile, AXLES, WELL_RADIUS, opening

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--port',type=int,required=True);ap.add_argument('--apply',action='store_true');a=ap.parse_args()
 def q(n,**p):
  req=urllib.request.Request(f'http://127.0.0.1:{a.port}/api/commands',data=json.dumps({'type':'ExecuteCommand','command':n,'params':p}).encode(),headers={'Content-Type':'application/json'})
  return json.load(urllib.request.urlopen(req,timeout=60))['data']
 docs=q('ListOpenDocuments')['open_documents'];doc=next(d['doc_id'] for d in docs if d['kind']=='usd' and d['origin'].get('path')==str(ROOT/'components/body.usda'))
 state=q('InspectUsdDocument',doc_id=doc,path='/Body');gen=state['generation'];ops=[]
 def attr(path,name,typ,value):ops.append({'SetAttribute':{'edit_target':'@root@','path':path,'name':name,'type_name':typ,'value':str(value)}})
 def mesh(path,points,faces):
  # Area-weighted normals shared at coincident vertices, preserving hard corners.
  ns=[];groups=collections.defaultdict(list)
  for face in faces:
   u,v,w=(points[i] for i in face[:3]);ab=[v[i]-u[i] for i in range(3)];ac=[w[i]-u[i] for i in range(3)]
   n=(ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]);norm=math.sqrt(sum(c*c for c in n));n=tuple(c/max(norm,1e-12) for c in n)
   for i in face:groups[tuple(round(c,6) for c in points[i])].append(n)
   ns.extend([n]*len(face))
  # Points are intentionally face-local, preserving wheel-opening/cap boundaries.
  normals=[]
  for point,own in zip(points,ns):
   smooth=[n for n in groups[tuple(round(c,6) for c in point)] if sum(x*y for x,y in zip(n,own))>.65]
   n=[sum(v[i] for v in smooth) for i in range(3)];m=math.sqrt(sum(c*c for c in n));normals.append(tuple(round(c/max(m,1e-12),7) for c in n))
  for name,typ,value in [('points','point3f[]',points),('faceVertexCounts','int[]',[len(f) for f in faces]),('faceVertexIndices','int[]',[i for f in faces for i in f]),('normals','normal3f[]',normals)]:attr(path,name,typ,value)
  assert len(normals)==len(points) and all(abs(sum(c*c for c in n)-1)<1e-5 for n in normals)
 def quad_mesh(quads):
  pts=[];fs=[]
  for qd in quads:
   i=len(pts);pts+=qd;fs.append(tuple(range(i,i+len(qd))))
  return pts,fs
 zs=sorted(set([round(-2.25+i*.025,6) for i in range(181)]+[a+d for a in AXLES for d in [-WELL_RADIUS,0,WELL_RADIUS]]))
 fractions=[-1+i/16 for i in range(33)]
 def deck(f,z):
  width,height=profile(z)
  crown=.032*(1-f*f);shoulder=.045*(max(0,abs(f)-.84)/.16)**2
  return (round(width*f,6),round(height+crown-shoulder,6),z)
 quads=[]
 for za,zb in zip(zs,zs[1:]):
  for fa,fb in zip(fractions,fractions[1:]):quads.append([deck(fa,za),deck(fa,zb),deck(fb,zb),deck(fb,za)])
  axle=next((c for c in AXLES if abs((za+zb)/2-c)<WELL_RADIUS),None)
  la,lb=(-.265,-.265) if axle is None else (opening(za,axle),opening(zb,axle))
  for sign in [-1,1]:
   wa,ya=profile(za);wb,yb=profile(zb)
   v=[deck(sign,za),(sign*wa,la,za),(sign*wb,lb,zb),deck(sign,zb)]
   quads.append(v if sign<0 else v[::-1])
 for z in [-2.25,2.25]:
  # The cap must meet every transverse deck station. A flat shoulder-height
  # cap leaves an open crescent below the crowned deck.
  for fa,fb in zip(fractions,fractions[1:]):
   left,right=deck(fa,z),deck(fb,z)
   v=[(left[0],-.265,z),(right[0],-.265,z),right,left]
   quads.append(v if z>0 else v[::-1])
 mesh('/Body/Skin',*quad_mesh(quads))
 # Curved smoked glazing, with original perimeter and pillar mounts retained.
 rings=[(-.75,.745,.353),(-.15,.645,.70),(.62,.635,.68),(1.30,.74,.38)]
 qds=[]
 for a0,b0 in zip(rings,rings[1:]):
  for i in range(16):
   def p(t,f):
    z=a0[0]+(b0[0]-a0[0])*t;w=a0[1]+(b0[1]-a0[1])*t;y=a0[2]+(b0[2]-a0[2])*t
    return (round(w*f,6),round(y+.035*(1-f*f)*math.sin(math.pi*(z+.75)/2.05),6),round(z,6))
   for j in range(16):
    fa=-1+j/8;fb=-1+(j+1)/8
    qds.append([p(i/16,fa),p((i+1)/16,fa),p((i+1)/16,fb),p(i/16,fb)])
 mesh('/Body/GoldCanopy',*quad_mesh(qds))
 for name,color,metal,rough in [('White',(.82,.855,.9),.52,.18),('Glass',(.018,.031,.048),.32,.085),('SideGlass',(.012,.021,.032),.28,.11),('Carbon',(.012,.017,.025),.28,.24)]:
  path='/Body/Looks/'+name+'/Shader'
  attr(path,'inputs:diffuseColor','color3f',color);attr(path,'inputs:metallic','float',metal);attr(path,'inputs:roughness','float',rough)
 plan={'doc_id':doc,'parent_gen':gen,'label':'Refine cosmetic shell curvature, normals and neutral PBR finish','ops':ops}
 out=ROOT/'.scratch/body-finish-plan.json';out.write_text(json.dumps(plan))
 print(json.dumps({'dry_plan':str(out),'operations':len(ops),'generation':gen,'collision_or_dynamics_changes':0}))
 if a.apply:
  result=q('ApplyUsdOps',**plan);print(json.dumps(result))
  st=q('InspectUsdDocument',doc_id=doc,path='/Body/Skin');assert st['generation']==result['generation'] and st['generation']>gen and not st['diagnostics']
  print('BODY_FINISH_TYPED_READBACK_PASS; visual checkpoint before save')
if __name__=='__main__':main()
