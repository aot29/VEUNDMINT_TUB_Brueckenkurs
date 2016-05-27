import math
import Blender
from Blender import NMesh

x = -1 * math.pi

mesh = NMesh.GetRaw()
vNew = NMesh.Vert( x, math.sin( x ), 0 )
mesh.verts.append( vNew )

while x < math.pi:
	x += 0.1
	vOld = vNew
	vNew = NMesh.Vert( x, math.sin( x ), 0 )
	mesh.verts.append( vNew )
	mesh.addEdge( vOld, vNew )

NMesh.PutRaw( mesh, "SineWave", 1 )
Blender.Redraw()
