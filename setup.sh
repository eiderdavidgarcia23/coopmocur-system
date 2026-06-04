#!/bin/bash
DEST=~/coopmocur-system
echo ""
echo "================================"
echo "  COOPMOCUR — Instalando...     "
echo "================================"

cat > "$DEST/firebase-db.js" << 'FBEOF'
import { initializeApp } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-app.js";
import { getDatabase, ref, push, remove, update, onValue } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-database.js";

const app = initializeApp({ databaseURL: "https://coopmocur-default-rtdb.firebaseio.com" });
const db = getDatabase(app);
const repuestosRef = ref(db, 'repuestos');

window.guardarEnFirebase = function(nuevo) { push(repuestosRef, nuevo); };
window.eliminarDeFirebase = function(key) { remove(ref(db, 'repuestos/' + key)); };
window.actualizarEnFirebase = function(key, cambios) { update(ref(db, 'repuestos/' + key), cambios); };

onValue(repuestosRef, (snapshot) => {
    const data = snapshot.val();
    const lista = data ? Object.entries(data).map(([k, v]) => ({ ...v, _key: k })) : [];
    if (window.actualizarInventarioDesdeFirebase) window.actualizarInventarioDesdeFirebase(lista);
});
FBEOF
echo "✅ firebase-db.js actualizado"

cat > "$DEST/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>COOPMOCUR</title>
<style>
*{box-sizing:border-box;margin:0;padding:0;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f1f5f9;min-height:100vh;color:#1e293b}
.header{background:#1e3a8a;color:#fff;padding:14px 16px;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,0.2)}
.header h1{font-size:1.1rem;font-weight:800;letter-spacing:1px}
.header p{font-size:0.7rem;color:#93c5fd;margin-top:2px}
.header-fecha{font-size:0.7rem;color:#93c5fd;font-family:monospace;text-align:right}
.tabs{display:flex;background:#fff;border-bottom:1px solid #e2e8f0;position:sticky;top:62px;z-index:99;box-shadow:0 1px 4px rgba(0,0,0,0.06)}
.tab{flex:1;padding:12px 4px;font-size:0.75rem;font-weight:600;color:#64748b;border:none;background:none;cursor:pointer;border-bottom:3px solid transparent}
.tab.active{color:#1d4ed8;border-bottom:3px solid #2563eb;font-weight:700}
.main{padding:16px;max-width:600px;margin:0 auto;padding-bottom:80px}
.section-title{font-size:1.1rem;font-weight:700;color:#374151;margin-bottom:4px}
.section-sub{font-size:0.75rem;color:#9ca3af;margin-bottom:12px}
.btn{padding:10px 16px;border:none;border-radius:10px;font-weight:700;cursor:pointer;font-size:0.85rem}
.btn-green{background:#059669;color:#fff}
.btn-blue{background:#2563eb;color:#fff}
.btn-gray{background:#e5e7eb;color:#374151}
.btn-full{width:100%;padding:13px;border-radius:12px;font-size:0.9rem}
.search{width:100%;padding:11px 14px;border:1px solid #d1d5db;border-radius:12px;font-size:0.9rem;background:#fff;margin-bottom:12px;outline:none}
.search:focus{border-color:#3b82f6;box-shadow:0 0 0 2px rgba(59,130,246,0.2)}
.card{background:#fff;border-radius:14px;padding:14px;margin-bottom:10px;border:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center;box-shadow:0 1px 3px rgba(0,0,0,0.05)}
.card.bajo{background:#fff5f5;border-color:#fecaca}
.card-name{font-weight:700;font-size:0.9rem;color:#1e293b;text-transform:uppercase}
.card-price{font-size:0.78rem;color:#64748b;margin-top:3px}
.card-price span{color:#059669;font-weight:700}
.badge{display:inline-block;padding:4px 12px;border-radius:999px;font-size:0.85rem;font-weight:700}
.badge-ok{background:#dbeafe;color:#1d4ed8}
.badge-bajo{background:#fee2e2;color:#dc2626}
.card-actions{display:flex;flex-direction:column;gap:6px;margin-left:10px}
.btn-edit{background:#eff6ff;color:#2563eb;padding:6px 10px;font-size:0.75rem;border-radius:8px;border:none;cursor:pointer;font-weight:700}
.btn-del{background:#fff5f5;color:#ef4444;padding:6px 10px;font-size:0.75rem;border-radius:8px;border:none;cursor:pointer;font-weight:700}
.empty{border:2px dashed #d1d5db;border-radius:16px;padding:40px 20px;text-align:center;color:#9ca3af;background:#fff}
.empty-icon{font-size:2.5rem;margin-bottom:8px}
.form-box{background:#fff;border-radius:14px;padding:16px;border:1px solid #e5e7eb;box-shadow:0 1px 3px rgba(0,0,0,0.05)}
.form-group{margin-bottom:12px}
.form-label{display:block;font-size:0.75rem;font-weight:700;color:#6b7280;margin-bottom:5px;text-transform:uppercase}
.form-input{width:100%;padding:11px 13px;border:1px solid #d1d5db;border-radius:10px;font-size:0.9rem;background:#f9fafb;outline:none}
.form-input:focus{border-color:#3b82f6;box-shadow:0 0 0 2px rgba(59,130,246,0.15);background:#fff}
.form-select{width:100%;padding:11px 13px;border:1px solid #d1d5db;border-radius:10px;font-size:0.9rem;background:#f9fafb;outline:none}
.btn-row{display:flex;gap:10px;margin-top:14px}
.btn-row .btn{flex:1}
.historial-list{background:#fff;border-radius:14px;border:1px solid #e5e7eb;overflow:hidden;max-height:420px;overflow-y:auto}
.hist-item{padding:12px 14px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #f1f5f9;font-size:0.8rem}
.hist-item:last-child{border-bottom:none}
.hist-tipo{font-weight:700;margin-right:6px}
.hist-tipo.entrada{color:#2563eb}
.hist-tipo.venta{color:#059669}
.hist-fecha{color:#9ca3af;font-family:monospace;font-size:0.75rem}
.top-bar{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:14px}
.btn-red-sm{background:#fee2e2;color:#dc2626;padding:6px 10px;font-size:0.75rem;border-radius:8px;border:none;cursor:pointer;font-weight:700}
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.55);z-index:200;justify-content:center;align-items:center;padding:16px}
.modal-overlay.visible{display:flex}
.modal{background:#fff;border-radius:18px;padding:22px;width:100%;max-width:380px;box-shadow:0 8px 32px rgba(0,0,0,0.18)}
.modal h3{font-size:1rem;font-weight:700;color:#1e293b;margin-bottom:16px}
@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.fade{animation:fadeIn 0.2s ease}
</style>
</head>
<body>

<div class="header">
  <div><h1>COOPMOCUR 🚗</h1><p>MÓDULO INTEGRAL DE REPUESTOS</p></div>
  <span class="header-fecha" id="fecha-header"></span>
</div>

<div class="tabs">
  <button class="tab active" id="tab-STOCK"     onclick="cambiarPestana('STOCK')">📦 STOCK</button>
  <button class="tab"        id="tab-ENTRADAS"  onclick="cambiarPestana('ENTRADAS')">📥 ENTRADAS</button>
  <button class="tab"        id="tab-VENTAS"    onclick="cambiarPestana('VENTAS')">💰 VENTAS</button>
  <button class="tab"        id="tab-HISTORIAL" onclick="cambiarPestana('HISTORIAL')">📋 HISTORIAL</button>
</div>

<div class="main" id="contenido-principal"></div>

<div class="modal-overlay" id="modal-agregar">
  <div class="modal">
    <h3>➕ Registrar Nuevo Repuesto</h3>
    <div class="form-group"><label class="form-label">Nombre de la pieza</label><input type="text" id="ins-nombre" placeholder="Ej. Kit de arrastre..." class="form-input"></div>
    <div class="form-group"><label class="form-label">Precio de venta ($)</label><input type="number" id="ins-precio" placeholder="Ej. 15000" class="form-input"></div>
    <div class="form-group"><label class="form-label">Cantidad disponible</label><input type="number" id="ins-cantidad" placeholder="Ej. 10" class="form-input"></div>
    <div class="btn-row">
      <button class="btn btn-gray" onclick="cerrarModalAgregar()">Cancelar</button>
      <button class="btn btn-green" onclick="procesarGuardarPieza()">Guardar Pieza</button>
    </div>
  </div>
</div>

<div class="modal-overlay" id="modal-editar">
  <div class="modal">
    <h3>✏️ Editar Repuesto</h3>
    <input type="hidden" id="edit-key">
    <div class="form-group"><label class="form-label">Nombre</label><input type="text" id="edit-nombre" class="form-input"></div>
    <div class="form-group"><label class="form-label">Precio ($)</label><input type="number" id="edit-precio" class="form-input"></div>
    <div class="form-group"><label class="form-label">Cantidad</label><input type="number" id="edit-cantidad" class="form-input"></div>
    <div class="btn-row">
      <button class="btn btn-gray" onclick="cerrarModalEditar()">Cancelar</button>
      <button class="btn btn-blue" onclick="procesarEditarPieza()">Guardar Cambios</button>
    </div>
  </div>
</div>

<script>
let inventario=[], pestanaActual='STOCK';
let historial=JSON.parse(localStorage.getItem('coopmocur_historial'))||[];

document.getElementById('fecha-header').innerText=
  new Date().toLocaleDateString('es-ES',{weekday:'short',day:'numeric',month:'short'}).toUpperCase();

function cambiarPestana(p){
  pestanaActual=p;
  ['STOCK','ENTRADAS','VENTAS','HISTORIAL'].forEach(t=>document.getElementById('tab-'+t).classList.remove('active'));
  document.getElementById('tab-'+p).classList.add('active');
  renderizar();
}

function renderizar(){
  const c=document.getElementById('contenido-principal');
  if(pestanaActual==='STOCK')     c.innerHTML=vistaStock();
  if(pestanaActual==='ENTRADAS')  c.innerHTML=vistaEntradas();
  if(pestanaActual==='VENTAS')    c.innerHTML=vistaVentas();
  if(pestanaActual==='HISTORIAL') c.innerHTML=vistaHistorial();
}

function vistaStock(){
  const bajos=inventario.filter(r=>r.cantidad<=3).length;
  return '<div class="fade"><div class="top-bar"><div><div class="section-title">REPUESTOS EN STOCK</div><div class="section-sub">'+inventario.length+' repuesto(s)'+(bajos>0?' &middot; <b style="color:#dc2626">'+bajos+' stock bajo</b>':'')+'</div></div><button class="btn btn-green" onclick="abrirModalAgregar()">+ AGREGAR</button></div><input type="text" class="search" id="busqueda" onkeyup="filtrarStock()" placeholder="🔍 Buscar por nombre..."><div id="lista-stock">'+generarListaStock(inventario)+'</div></div>';
}

function generarListaStock(lista){
  if(!lista.length) return '<div class="empty"><div class="empty-icon">📦</div><p>No hay repuestos en el sistema.</p></div>';
  return lista.map(r=>{
    const bajo=r.cantidad<=3;
    return '<div class="card'+(bajo?' bajo':'')+'"><div><div class="card-name">'+r.nombre+'</div><div class="card-price">Precio: <span>$'+Number(r.precio).toLocaleString()+'</span></div></div><div style="display:flex;align-items:center;gap:8px"><div style="text-align:center"><div style="font-size:0.7rem;color:#9ca3af;font-weight:700">CANT.</div><span class="badge '+(bajo?'badge-bajo':'badge-ok')+'">'+r.cantidad+'</span></div><div class="card-actions"><button class="btn-edit" onclick="abrirModalEditar(\''+r._key+'\')">✏️</button><button class="btn-del" onclick="eliminarPieza(\''+r._key+'\')">🗑️</button></div></div></div>';
  }).join('');
}

function filtrarStock(){
  const b=document.getElementById('busqueda').value.toLowerCase();
  document.getElementById('lista-stock').innerHTML=generarListaStock(inventario.filter(r=>r.nombre.toLowerCase().includes(b)));
}

function vistaEntradas(){
  const ops=inventario.map(r=>'<option value="'+r._key+'">'+r.nombre+' (Actual: '+r.cantidad+')</option>').join('')||'<option>Sin repuestos</option>';
  return '<div class="fade"><div class="section-title" style="margin-bottom:14px">📥 REGISTRAR ENTRADA DE STOCK</div><div class="form-box"><div class="form-group"><label class="form-label">Seleccionar Repuesto</label><select id="select-entrada" class="form-select">'+ops+'</select></div><div class="form-group"><label class="form-label">Cantidad que ingresa</label><input type="number" id="cant-entrada" placeholder="Ej. 5" class="form-input"></div><button class="btn btn-blue btn-full" onclick="procesarEntrada()">SUMAR AL STOCK</button></div></div>';
}

function procesarEntrada(){
  const key=document.getElementById('select-entrada').value;
  const cant=parseInt(document.getElementById('cant-entrada').value);
  if(!key||isNaN(cant)||cant<=0) return alert('Ingresa datos válidos');
  const item=inventario.find(r=>r._key===key);
  if(item){window.actualizarEnFirebase(key,{cantidad:item.cantidad+cant});registrarHistorial('ENTRADA','Surtido: +'+cant+' u. de '+item.nombre);alert('✅ Stock actualizado.');cambiarPestana('STOCK');}
}

function vistaVentas(){
  const ops=inventario.map(r=>'<option value="'+r._key+'">'+r.nombre+' - $'+r.precio+' (Disp: '+r.cantidad+')</option>').join('')||'<option>Sin repuestos</option>';
  return '<div class="fade"><div class="section-title" style="margin-bottom:14px">💰 REGISTRAR NUEVA VENTA</div><div class="form-box"><div class="form-group"><label class="form-label">Seleccionar Repuesto</label><select id="select-venta" class="form-select">'+ops+'</select></div><div class="form-group"><label class="form-label">Cantidad a vender</label><input type="number" id="cant-venta" placeholder="Ej. 2" class="form-input"></div><button class="btn btn-green btn-full" onclick="procesarVenta()">CONFIRMAR VENTA</button></div></div>';
}

function procesarVenta(){
  const key=document.getElementById('select-venta').value;
  const cant=parseInt(document.getElementById('cant-venta').value);
  if(!key||isNaN(cant)||cant<=0) return alert('Ingresa datos válidos');
  const item=inventario.find(r=>r._key===key);
  if(item){
    if(item.cantidad<cant) return alert('❌ Stock insuficiente. Solo hay '+item.cantidad+' u.');
    window.actualizarEnFirebase(key,{cantidad:item.cantidad-cant});
    registrarHistorial('VENTA','Vendido: '+cant+' u. de '+item.nombre+' (Total: $'+(cant*item.precio).toLocaleString()+')');
    alert('🎉 Venta registrada.');cambiarPestana('STOCK');
  }
}

function vistaHistorial(){
  const filas=!historial.length?'<p style="padding:20px;text-align:center;color:#9ca3af;font-size:0.85rem">No hay movimientos registrados.</p>':historial.map(h=>'<div class="hist-item"><div><span class="hist-tipo '+(h.tipo==='ENTRADA'?'entrada':'venta')+'">['+h.tipo+']</span><span>'+h.detalle+'</span></div><span class="hist-fecha">'+h.fecha+'</span></div>').join('');
  return '<div class="fade"><div class="top-bar"><div class="section-title">📋 HISTORIAL</div><button class="btn-red-sm" onclick="limpiarHistorial()">BORRAR TODO</button></div><div class="historial-list">'+filas+'</div></div>';
}

function registrarHistorial(tipo,detalle){
  const a=new Date();
  historial.unshift({tipo,detalle,fecha:a.getHours()+':'+a.getMinutes().toString().padStart(2,'0')});
  localStorage.setItem('coopmocur_historial',JSON.stringify(historial));
}

function limpiarHistorial(){
  if(confirm('¿Borrar historial?')){historial=[];localStorage.setItem('coopmocur_historial','[]');renderizar();}
}

function abrirModalAgregar(){
  ['ins-nombre','ins-precio','ins-cantidad'].forEach(id=>document.getElementById(id).value='');
  document.getElementById('modal-agregar').classList.add('visible');
}
function cerrarModalAgregar(){document.getElementById('modal-agregar').classList.remove('visible');}
function procesarGuardarPieza(){
  const nombre=document.getElementById('ins-nombre').value.trim();
  const precio=parseFloat(document.getElementById('ins-precio').value);
  const cantidad=parseInt(document.getElementById('ins-cantidad').value);
  if(!nombre||isNaN(precio)||isNaN(cantidad)) return alert('Rellena todos los campos.');
  window.guardarEnFirebase({nombre,precio,cantidad});
  cerrarModalAgregar();
}

function abrirModalEditar(key){
  const item=inventario.find(r=>r._key===key);
  if(!item) return;
  document.getElementById('edit-key').value=key;
  document.getElementById('edit-nombre').value=item.nombre;
  document.getElementById('edit-precio').value=item.precio;
  document.getElementById('edit-cantidad').value=item.cantidad;
  document.getElementById('modal-editar').classList.add('visible');
}
function cerrarModalEditar(){document.getElementById('modal-editar').classList.remove('visible');}
function procesarEditarPieza(){
  const key=document.getElementById('edit-key').value;
  const nombre=document.getElementById('edit-nombre').value.trim();
  const precio=parseFloat(document.getElementById('edit-precio').value);
  const cantidad=parseInt(document.getElementById('edit-cantidad').value);
  if(!nombre||isNaN(precio)||isNaN(cantidad)) return alert('Rellena todos los campos.');
  window.actualizarEnFirebase(key,{nombre,precio,cantidad});
  cerrarModalEditar();
}

function eliminarPieza(key){
  const item=inventario.find(r=>r._key===key);
  if(item&&confirm('¿Eliminar "'+item.nombre+'"?')) window.eliminarDeFirebase(key);
}

window.actualizarInventarioDesdeFirebase=function(lista){inventario=lista;renderizar();};
renderizar();
</script>
<script type="module" src="firebase-db.js"></script>
</body>
</html>
HTMLEOF
echo "✅ index.html actualizado"
echo "// reemplazado" > "$DEST/app.js"
echo "" > "$DEST/styles.css"
echo ""
echo "================================"
echo "  Instalacion completa!         "
echo "  python -m http.server 8080    "
echo "================================"
