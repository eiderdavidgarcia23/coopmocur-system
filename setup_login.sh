#!/bin/bash
DEST=~/coopmocur-system
echo ""
echo "================================"
echo "  COOPMOCUR — Instalando Login  "
echo "================================"

cat > "$DEST/firebase-db.js" << 'FBEOF'
import { initializeApp } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-app.js";
import { getDatabase, ref, push, remove, update, onValue, get, set } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-database.js";

const app = initializeApp({ databaseURL: "https://coopmocur-default-rtdb.firebaseio.com" });
const db = getDatabase(app);
const repuestosRef = ref(db, 'repuestos');
const usuariosRef = ref(db, 'usuarios');

// ── REPUESTOS ──
window.guardarEnFirebase = (nuevo) => push(repuestosRef, nuevo);
window.eliminarDeFirebase = (key) => remove(ref(db, 'repuestos/' + key));
window.actualizarEnFirebase = (key, cambios) => update(ref(db, 'repuestos/' + key), cambios);

onValue(repuestosRef, (snapshot) => {
    const data = snapshot.val();
    const lista = data ? Object.entries(data).map(([k,v]) => ({...v, _key:k})) : [];
    if (window.actualizarInventarioDesdeFirebase) window.actualizarInventarioDesdeFirebase(lista);
});

// ── USUARIOS ──
window.crearUsuarioEnFirebase = async function(usuario, password, rol, nombre) {
    const snap = await get(usuariosRef);
    const data = snap.val() || {};
    // Verificar si ya existe
    const existe = Object.values(data).some(u => u.usuario === usuario);
    if (existe) return { ok: false, msg: 'El usuario ya existe' };
    await push(usuariosRef, { usuario, password, rol, nombre, creado: new Date().toLocaleDateString('es-ES') });
    return { ok: true };
};

window.eliminarUsuarioDeFirebase = (key) => remove(ref(db, 'usuarios/' + key));

window.loginConFirebase = async function(usuario, password) {
    const snap = await get(usuariosRef);
    const data = snap.val();
    if (!data) return null;
    const entrada = Object.entries(data).find(([k,v]) => v.usuario === usuario && v.password === password);
    if (!entrada) return null;
    return { ...entrada[1], _key: entrada[0] };
};

window.obtenerUsuarios = async function() {
    const snap = await get(usuariosRef);
    const data = snap.val() || {};
    return Object.entries(data).map(([k,v]) => ({...v, _key:k}));
};

// Crear admin por defecto si no existe
get(usuariosRef).then(snap => {
    const data = snap.val() || {};
    const tieneAdmin = Object.values(data).some(u => u.usuario === 'eider');
    if (!tieneAdmin) {
        push(usuariosRef, { usuario: 'eider', password: '1234', rol: 'admin', nombre: 'Eider', creado: new Date().toLocaleDateString('es-ES') });
    }
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

/* LOGIN */
.login-bg{min-height:100vh;background:linear-gradient(135deg,#1e3a8a,#1d4ed8);display:flex;align-items:center;justify-content:center;padding:20px}
.login-box{background:#fff;border-radius:20px;padding:32px 24px;width:100%;max-width:360px;box-shadow:0 8px 32px rgba(0,0,0,0.2)}
.login-logo{text-align:center;margin-bottom:24px}
.login-logo h1{font-size:1.8rem;font-weight:800;color:#1e3a8a;letter-spacing:1px}
.login-logo p{font-size:0.75rem;color:#64748b;margin-top:4px}
.login-label{display:block;font-size:0.75rem;font-weight:700;color:#6b7280;margin-bottom:5px;text-transform:uppercase}
.login-input{width:100%;padding:13px;border:1px solid #d1d5db;border-radius:12px;font-size:0.95rem;background:#f9fafb;outline:none;margin-bottom:14px}
.login-input:focus{border-color:#3b82f6;box-shadow:0 0 0 2px rgba(59,130,246,0.15)}
.login-btn{width:100%;padding:14px;background:#1e3a8a;color:#fff;border:none;border-radius:12px;font-size:1rem;font-weight:700;cursor:pointer;margin-top:4px}
.login-btn:active{background:#1d4ed8}
.login-error{background:#fee2e2;color:#dc2626;padding:10px 14px;border-radius:10px;font-size:0.82rem;font-weight:600;margin-bottom:12px;display:none}

/* APP */
.header{background:#1e3a8a;color:#fff;padding:14px 16px;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,0.2)}
.header-left h1{font-size:1.1rem;font-weight:800;letter-spacing:1px}
.header-left p{font-size:0.7rem;color:#93c5fd;margin-top:2px}
.header-right{display:flex;flex-direction:column;align-items:flex-end;gap:4px}
.header-user{font-size:0.7rem;color:#93c5fd;font-family:monospace}
.btn-logout{background:rgba(255,255,255,0.15);border:none;color:#fff;padding:5px 10px;border-radius:8px;font-size:0.7rem;font-weight:700;cursor:pointer}
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
.btn-red{background:#ef4444;color:#fff}
.btn-full{width:100%;padding:13px;border-radius:12px;font-size:0.9rem}
.search{width:100%;padding:11px 14px;border:1px solid #d1d5db;border-radius:12px;font-size:0.9rem;background:#fff;margin-bottom:12px;outline:none}
.card{background:#fff;border-radius:14px;padding:14px;margin-bottom:10px;border:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center;box-shadow:0 1px 3px rgba(0,0,0,0.05)}
.card.bajo{background:#fff5f5;border-color:#fecaca}
.card-name{font-weight:700;font-size:0.9rem;color:#1e293b;text-transform:uppercase}
.card-price{font-size:0.78rem;color:#64748b;margin-top:3px}
.card-price span{color:#059669;font-weight:700}
.badge{display:inline-block;padding:4px 12px;border-radius:999px;font-size:0.85rem;font-weight:700}
.badge-ok{background:#dbeafe;color:#1d4ed8}
.badge-bajo{background:#fee2e2;color:#dc2626}
.badge-admin{background:#fef3c7;color:#92400e;padding:3px 8px;border-radius:6px;font-size:0.7rem;font-weight:700}
.badge-emp{background:#e0e7ff;color:#3730a3;padding:3px 8px;border-radius:6px;font-size:0.7rem;font-weight:700}
.card-actions{display:flex;flex-direction:column;gap:6px;margin-left:10px}
.btn-edit{background:#eff6ff;color:#2563eb;padding:6px 10px;font-size:0.75rem;border-radius:8px;border:none;cursor:pointer;font-weight:700}
.btn-del{background:#fff5f5;color:#ef4444;padding:6px 10px;font-size:0.75rem;border-radius:8px;border:none;cursor:pointer;font-weight:700}
.empty{border:2px dashed #d1d5db;border-radius:16px;padding:40px 20px;text-align:center;color:#9ca3af;background:#fff}
.form-box{background:#fff;border-radius:14px;padding:16px;border:1px solid #e5e7eb;box-shadow:0 1px 3px rgba(0,0,0,0.05)}
.form-group{margin-bottom:12px}
.form-label{display:block;font-size:0.75rem;font-weight:700;color:#6b7280;margin-bottom:5px;text-transform:uppercase}
.form-input{width:100%;padding:11px 13px;border:1px solid #d1d5db;border-radius:10px;font-size:0.9rem;background:#f9fafb;outline:none}
.form-input:focus{border-color:#3b82f6;background:#fff}
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
.usuario-card{background:#fff;border-radius:14px;padding:14px;margin-bottom:10px;border:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center}
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.55);z-index:200;justify-content:center;align-items:center;padding:16px}
.modal-overlay.visible{display:flex}
.modal{background:#fff;border-radius:18px;padding:22px;width:100%;max-width:380px;box-shadow:0 8px 32px rgba(0,0,0,0.18)}
.modal h3{font-size:1rem;font-weight:700;color:#1e293b;margin-bottom:16px}
#toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%) translateY(100px);background:#1e293b;color:#fff;padding:12px 22px;border-radius:12px;font-size:0.85rem;font-weight:600;z-index:9999;opacity:0;transition:all 0.3s ease;pointer-events:none;white-space:nowrap}
#toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.fade{animation:fadeIn 0.2s ease}
</style>
</head>
<body>

<!-- LOGIN -->
<div id="pantalla-login" class="login-bg">
  <div class="login-box">
    <div class="login-logo">
      <h1>COOPMOCUR 🚗</h1>
      <p>SISTEMA INTEGRAL DE REPUESTOS</p>
    </div>
    <div id="login-error" class="login-error">Usuario o contraseña incorrectos</div>
    <label class="login-label">Usuario</label>
    <input type="text" id="login-usuario" placeholder="Ej. eider" class="login-input" autocomplete="off">
    <label class="login-label">Contraseña</label>
    <input type="password" id="login-password" placeholder="••••••" class="login-input">
    <button class="login-btn" onclick="intentarLogin()">INGRESAR</button>
  </div>
</div>

<!-- APP PRINCIPAL -->
<div id="pantalla-app" style="display:none">
  <div class="header">
    <div class="header-left">
      <h1>COOPMOCUR 🚗</h1>
      <p>MÓDULO INTEGRAL DE REPUESTOS</p>
    </div>
    <div class="header-right">
      <span class="header-user" id="header-usuario"></span>
      <button class="btn-logout" onclick="cerrarSesion()">Salir</button>
    </div>
  </div>

  <div class="tabs" id="barra-tabs">
    <button class="tab active" id="tab-STOCK"     onclick="cambiarPestana('STOCK')">📦 STOCK</button>
    <button class="tab"        id="tab-ENTRADAS"  onclick="cambiarPestana('ENTRADAS')">📥 ENTRADAS</button>
    <button class="tab"        id="tab-VENTAS"    onclick="cambiarPestana('VENTAS')">💰 VENTAS</button>
    <button class="tab"        id="tab-HISTORIAL" onclick="cambiarPestana('HISTORIAL')">📋 HISTORIAL</button>
    <button class="tab"        id="tab-USUARIOS"  onclick="cambiarPestana('USUARIOS')" style="display:none">👥 USUARIOS</button>
  </div>

  <div class="main" id="contenido-principal"></div>
</div>

<!-- MODAL AGREGAR REPUESTO -->
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

<!-- MODAL EDITAR REPUESTO -->
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

<!-- MODAL CREAR USUARIO -->
<div class="modal-overlay" id="modal-usuario">
  <div class="modal">
    <h3>👤 Crear Nuevo Usuario</h3>
    <div class="form-group"><label class="form-label">Nombre completo</label><input type="text" id="nuevo-nombre" placeholder="Ej. Carlos" class="form-input"></div>
    <div class="form-group"><label class="form-label">Usuario</label><input type="text" id="nuevo-usuario" placeholder="Ej. carlos" class="form-input" autocomplete="off"></div>
    <div class="form-group"><label class="form-label">Contraseña</label><input type="password" id="nuevo-password" placeholder="••••••" class="form-input"></div>
    <div class="form-group"><label class="form-label">Rol</label>
      <select id="nuevo-rol" class="form-select">
        <option value="empleado">Empleado</option>
        <option value="admin">Administrador</option>
      </select>
    </div>
    <div class="btn-row">
      <button class="btn btn-gray" onclick="cerrarModalUsuario()">Cancelar</button>
      <button class="btn btn-blue" onclick="procesarCrearUsuario()">Crear Usuario</button>
    </div>
  </div>
</div>

<div id="toast"></div>

<script>
// ── ESTADO ──
let inventario = [];
let pestanaActual = 'STOCK';
let historial = JSON.parse(localStorage.getItem('coopmocur_historial')) || [];
let usuarioActual = null;

// ── TOAST ──
function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(window._toastTimer);
  window._toastTimer = setTimeout(() => t.classList.remove('show'), 2800);
}

// ── LOGIN ──
async function intentarLogin() {
  const usuario = document.getElementById('login-usuario').value.trim().toLowerCase();
  const password = document.getElementById('login-password').value;
  if (!usuario || !password) { toast('⚠️ Ingresa usuario y contraseña'); return; }
  const btn = document.querySelector('.login-btn');
  btn.textContent = 'Verificando...';
  btn.disabled = true;
  const resultado = await window.loginConFirebase(usuario, password);
  btn.textContent = 'INGRESAR';
  btn.disabled = false;
  if (!resultado) {
    document.getElementById('login-error').style.display = 'block';
    return;
  }
  document.getElementById('login-error').style.display = 'none';
  usuarioActual = resultado;
  iniciarApp();
}

// Permitir Enter en login
document.getElementById('login-password').addEventListener('keydown', e => {
  if (e.key === 'Enter') intentarLogin();
});

function iniciarApp() {
  document.getElementById('pantalla-login').style.display = 'none';
  document.getElementById('pantalla-app').style.display = 'block';
  document.getElementById('header-usuario').textContent = '👤 ' + usuarioActual.nombre + ' (' + usuarioActual.rol + ')';
  // Mostrar tab usuarios solo para admin
  if (usuarioActual.rol === 'admin') {
    document.getElementById('tab-USUARIOS').style.display = '';
  }
  renderizar();
}

function cerrarSesion() {
  if (confirm('¿Cerrar sesión?')) {
    usuarioActual = null;
    document.getElementById('pantalla-login').style.display = 'flex';
    document.getElementById('pantalla-app').style.display = 'none';
    document.getElementById('login-usuario').value = '';
    document.getElementById('login-password').value = '';
    document.getElementById('tab-USUARIOS').style.display = 'none';
    pestanaActual = 'STOCK';
  }
}

// ── TABS ──
function cambiarPestana(p) {
  pestanaActual = p;
  ['STOCK','ENTRADAS','VENTAS','HISTORIAL','USUARIOS'].forEach(t => {
    const el = document.getElementById('tab-' + t);
    if (el) el.classList.remove('active');
  });
  document.getElementById('tab-' + p).classList.add('active');
  renderizar();
}

// ── RENDER ──
function renderizar() {
  const c = document.getElementById('contenido-principal');
  if (!c) return;
  if (pestanaActual === 'STOCK')     c.innerHTML = vistaStock();
  if (pestanaActual === 'ENTRADAS')  c.innerHTML = vistaEntradas();
  if (pestanaActual === 'VENTAS')    c.innerHTML = vistaVentas();
  if (pestanaActual === 'HISTORIAL') c.innerHTML = vistaHistorial();
  if (pestanaActual === 'USUARIOS')  vistaUsuarios();
}

// ── STOCK ──
function vistaStock() {
  const esAdmin = usuarioActual && usuarioActual.rol === 'admin';
  const bajos = inventario.filter(r => r.cantidad <= 3).length;
  return '<div class="fade"><div class="top-bar"><div><div class="section-title">REPUESTOS EN STOCK</div><div class="section-sub">' + inventario.length + ' repuesto(s)' + (bajos > 0 ? ' · <b style="color:#dc2626">' + bajos + ' stock bajo</b>' : '') + '</div></div>' + (esAdmin ? '<button class="btn btn-green" onclick="abrirModalAgregar()">+ AGREGAR</button>' : '') + '</div><input type="text" class="search" id="busqueda" onkeyup="filtrarStock()" placeholder="🔍 Buscar por nombre..."><div id="lista-stock">' + generarListaStock(inventario) + '</div></div>';
}

function generarListaStock(lista) {
  const esAdmin = usuarioActual && usuarioActual.rol === 'admin';
  if (!lista.length) return '<div class="empty"><div style="font-size:2.5rem;margin-bottom:8px">📦</div><p>No hay repuestos en el sistema.</p></div>';
  return lista.map(r => {
    const bajo = r.cantidad <= 3;
    return '<div class="card' + (bajo ? ' bajo' : '') + '"><div><div class="card-name">' + r.nombre + '</div><div class="card-price">Precio: <span>$' + Number(r.precio).toLocaleString() + '</span></div></div><div style="display:flex;align-items:center;gap:8px"><div style="text-align:center"><div style="font-size:0.7rem;color:#9ca3af;font-weight:700">CANT.</div><span class="badge ' + (bajo ? 'badge-bajo' : 'badge-ok') + '">' + r.cantidad + '</span></div>' + (esAdmin ? '<div class="card-actions"><button class="btn-edit" onclick="abrirModalEditar(\'' + r._key + '\')">✏️</button><button class="btn-del" onclick="eliminarPieza(\'' + r._key + '\')">🗑️</button></div>' : '') + '</div></div>';
  }).join('');
}

function filtrarStock() {
  const b = document.getElementById('busqueda').value.toLowerCase();
  document.getElementById('lista-stock').innerHTML = generarListaStock(inventario.filter(r => r.nombre.toLowerCase().includes(b)));
}

// ── ENTRADAS ──
function vistaEntradas() {
  const ops = inventario.map(r => '<option value="' + r._key + '">' + r.nombre + ' (Actual: ' + r.cantidad + ')</option>').join('') || '<option>Sin repuestos</option>';
  return '<div class="fade"><div class="section-title" style="margin-bottom:14px">📥 REGISTRAR ENTRADA DE STOCK</div><div class="form-box"><div class="form-group"><label class="form-label">Seleccionar Repuesto</label><select id="select-entrada" class="form-select">' + ops + '</select></div><div class="form-group"><label class="form-label">Cantidad que ingresa</label><input type="number" id="cant-entrada" placeholder="Ej. 5" class="form-input"></div><button class="btn btn-blue btn-full" onclick="procesarEntrada()">SUMAR AL STOCK</button></div></div>';
}

function procesarEntrada() {
  const key = document.getElementById('select-entrada').value;
  const cant = parseInt(document.getElementById('cant-entrada').value);
  if (!key || isNaN(cant) || cant <= 0) return toast('⚠️ Ingresa datos válidos');
  const item = inventario.find(r => r._key === key);
  if (item) {
    window.actualizarEnFirebase(key, { cantidad: item.cantidad + cant });
    registrarHistorial('ENTRADA', 'Surtido: +' + cant + ' u. de ' + item.nombre);
    toast('✅ Stock actualizado.');
    cambiarPestana('STOCK');
  }
}

// ── VENTAS ──
function vistaVentas() {
  const ops = inventario.map(r => '<option value="' + r._key + '">' + r.nombre + ' - $' + r.precio + ' (Disp: ' + r.cantidad + ')</option>').join('') || '<option>Sin repuestos</option>';
  return '<div class="fade"><div class="section-title" style="margin-bottom:14px">💰 REGISTRAR NUEVA VENTA</div><div class="form-box"><div class="form-group"><label class="form-label">Seleccionar Repuesto</label><select id="select-venta" class="form-select">' + ops + '</select></div><div class="form-group"><label class="form-label">Cantidad a vender</label><input type="number" id="cant-venta" placeholder="Ej. 2" class="form-input"></div><button class="btn btn-green btn-full" onclick="procesarVenta()">CONFIRMAR VENTA</button></div></div>';
}

function procesarVenta() {
  const key = document.getElementById('select-venta').value;
  const cant = parseInt(document.getElementById('cant-venta').value);
  if (!key || isNaN(cant) || cant <= 0) return toast('⚠️ Ingresa datos válidos');
  const item = inventario.find(r => r._key === key);
  if (item) {
    if (item.cantidad < cant) return toast('❌ Stock insuficiente: ' + item.cantidad + ' u.');
    window.actualizarEnFirebase(key, { cantidad: item.cantidad - cant });
    registrarHistorial('VENTA', 'Vendido: ' + cant + ' u. de ' + item.nombre + ' (Total: $' + (cant * item.precio).toLocaleString() + ')');
    toast('🎉 Venta registrada.');
    cambiarPestana('STOCK');
  }
}

// ── HISTORIAL ──
function vistaHistorial() {
  const filas = !historial.length ? '<p style="padding:20px;text-align:center;color:#9ca3af;font-size:0.85rem">No hay movimientos registrados.</p>' : historial.map(h => '<div class="hist-item"><div><span class="hist-tipo ' + (h.tipo === 'ENTRADA' ? 'entrada' : 'venta') + '">[' + h.tipo + ']</span><span>' + h.detalle + '</span></div><span class="hist-fecha">' + h.fecha + '</span></div>').join('');
  return '<div class="fade"><div class="top-bar"><div class="section-title">📋 HISTORIAL</div>' + (usuarioActual && usuarioActual.rol === 'admin' ? '<button class="btn-red-sm" onclick="limpiarHistorial()">BORRAR TODO</button>' : '') + '</div><div class="historial-list">' + filas + '</div></div>';
}

function registrarHistorial(tipo, detalle) {
  const a = new Date();
  historial.unshift({ tipo, detalle, fecha: a.getHours() + ':' + a.getMinutes().toString().padStart(2, '0'), usuario: usuarioActual ? usuarioActual.nombre : '' });
  localStorage.setItem('coopmocur_historial', JSON.stringify(historial));
}

function limpiarHistorial() {
  if (confirm('¿Borrar historial?')) { historial = []; localStorage.setItem('coopmocur_historial', '[]'); renderizar(); }
}

// ── USUARIOS (solo admin) ──
async function vistaUsuarios() {
  const c = document.getElementById('contenido-principal');
  c.innerHTML = '<div class="fade"><div class="top-bar"><div class="section-title">👥 GESTIÓN DE USUARIOS</div><button class="btn btn-blue" onclick="abrirModalUsuario()">+ CREAR</button></div><div id="lista-usuarios"><p style="color:#9ca3af;font-size:0.85rem;text-align:center;padding:20px">Cargando...</p></div></div>';
  const usuarios = await window.obtenerUsuarios();
  const filas = usuarios.map(u => '<div class="usuario-card"><div><div style="font-weight:700;font-size:0.9rem">' + u.nombre + '</div><div style="font-size:0.78rem;color:#64748b;margin-top:3px">@' + u.usuario + ' · <span class="' + (u.rol === 'admin' ? 'badge-admin' : 'badge-emp') + '">' + u.rol + '</span></div></div>' + (u.usuario !== 'eider' ? '<button class="btn-del" onclick="eliminarUsuario(\'' + u._key + '\',\'' + u.nombre + '\')">🗑️</button>' : '<span style="font-size:0.7rem;color:#9ca3af">Admin</span>') + '</div>').join('');
  document.getElementById('lista-usuarios').innerHTML = filas || '<p style="color:#9ca3af;font-size:0.85rem;text-align:center;padding:20px">No hay usuarios.</p>';
}

function abrirModalUsuario() {
  ['nuevo-nombre','nuevo-usuario','nuevo-password'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('modal-usuario').classList.add('visible');
}
function cerrarModalUsuario() { document.getElementById('modal-usuario').classList.remove('visible'); }

async function procesarCrearUsuario() {
  const nombre = document.getElementById('nuevo-nombre').value.trim();
  const usuario = document.getElementById('nuevo-usuario').value.trim().toLowerCase();
  const password = document.getElementById('nuevo-password').value;
  const rol = document.getElementById('nuevo-rol').value;
  if (!nombre || !usuario || !password) return toast('⚠️ Rellena todos los campos.');
  const res = await window.crearUsuarioEnFirebase(usuario, password, rol, nombre);
  if (!res.ok) return toast('❌ ' + res.msg);
  toast('✅ Usuario ' + usuario + ' creado.');
  cerrarModalUsuario();
  vistaUsuarios();
}

async function eliminarUsuario(key, nombre) {
  if (confirm('¿Eliminar al usuario ' + nombre + '?')) {
    await window.eliminarUsuarioDeFirebase(key);
    toast('✅ Usuario eliminado.');
    vistaUsuarios();
  }
}

// ── MODALES REPUESTOS ──
function abrirModalAgregar() {
  ['ins-nombre','ins-precio','ins-cantidad'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('modal-agregar').classList.add('visible');
}
function cerrarModalAgregar() { document.getElementById('modal-agregar').classList.remove('visible'); }
function procesarGuardarPieza() {
  const nombre = document.getElementById('ins-nombre').value.trim();
  const precio = parseFloat(document.getElementById('ins-precio').value);
  const cantidad = parseInt(document.getElementById('ins-cantidad').value);
  if (!nombre || isNaN(precio) || isNaN(cantidad)) return toast('⚠️ Rellena todos los campos.');
  window.guardarEnFirebase({ nombre, precio, cantidad });
  cerrarModalAgregar();
}

function abrirModalEditar(key) {
  const item = inventario.find(r => r._key === key);
  if (!item) return;
  document.getElementById('edit-key').value = key;
  document.getElementById('edit-nombre').value = item.nombre;
  document.getElementById('edit-precio').value = item.precio;
  document.getElementById('edit-cantidad').value = item.cantidad;
  document.getElementById('modal-editar').classList.add('visible');
}
function cerrarModalEditar() { document.getElementById('modal-editar').classList.remove('visible'); }
function procesarEditarPieza() {
  const key = document.getElementById('edit-key').value;
  const nombre = document.getElementById('edit-nombre').value.trim();
  const precio = parseFloat(document.getElementById('edit-precio').value);
  const cantidad = parseInt(document.getElementById('edit-cantidad').value);
  if (!nombre || isNaN(precio) || isNaN(cantidad)) return toast('⚠️ Rellena todos los campos.');
  window.actualizarEnFirebase(key, { nombre, precio, cantidad });
  cerrarModalEditar();
}

function eliminarPieza(key) {
  const item = inventario.find(r => r._key === key);
  if (item && confirm('¿Eliminar "' + item.nombre + '"?')) window.eliminarDeFirebase(key);
}

// ── BRIDGE FIREBASE ──
window.actualizarInventarioDesdeFirebase = function(lista) {
  inventario = lista;
  if (usuarioActual) renderizar();
};

</script>
<script type="module" src="firebase-db.js"></script>
</body>
</html>
HTMLEOF
echo "✅ index.html actualizado"
echo "// reemplazado" > "$DEST/app.js"
echo ""
echo "================================"
echo "  Instalacion completa!         "
echo "  python -m http.server 8080    "
echo "================================"
