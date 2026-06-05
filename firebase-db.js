import { initializeApp } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-app.js";
import { getDatabase, ref, push, remove, update, onValue, get } from "https://www.gstatic.com/firebasejs/12.14.0/firebase-database.js";

const app = initializeApp({ databaseURL: "https://coopmocur-default-rtdb.firebaseio.com" });
const db = getDatabase(app);
const repuestosRef = ref(db, 'repuestos');
const usuariosRef = ref(db, 'usuarios');

window.guardarEnFirebase = (nuevo) => push(repuestosRef, nuevo);
window.eliminarDeFirebase = (key) => remove(ref(db, 'repuestos/' + key));
window.actualizarEnFirebase = (key, cambios) => update(ref(db, 'repuestos/' + key), cambios);

onValue(repuestosRef, (snapshot) => {
    const data = snapshot.val();
    const lista = data ? Object.entries(data).map(([k,v]) => ({...v, _key:k})) : [];
    if (window.actualizarInventarioDesdeFirebase) window.actualizarInventarioDesdeFirebase(lista);
});

window.loginConFirebase = async function(usuario, password) {
    try {
        const snap = await get(usuariosRef);
        const data = snap.val();
        if (!data) return null;
        const entrada = Object.entries(data).find(([k,v]) => 
            v.usuario === usuario.toLowerCase() && v.password === password
        );
        if (!entrada) return null;
        return { ...entrada[1], _key: entrada[0] };
    } catch(e) {
        console.error('Login error:', e);
        return null;
    }
};

window.crearUsuarioEnFirebase = async function(usuario, password, rol, nombre) {
    try {
        const snap = await get(usuariosRef);
        const data = snap.val() || {};
        const existe = Object.values(data).some(u => u.usuario === usuario.toLowerCase());
        if (existe) return { ok: false, msg: 'El usuario ya existe' };
        await push(usuariosRef, { usuario: usuario.toLowerCase(), password, rol, nombre, creado: new Date().toLocaleDateString('es-ES') });
        return { ok: true };
    } catch(e) {
        return { ok: false, msg: 'Error al crear usuario' };
    }
};

window.eliminarUsuarioDeFirebase = (key) => remove(ref(db, 'usuarios/' + key));

window.obtenerUsuarios = async function() {
    const snap = await get(usuariosRef);
    const data = snap.val() || {};
    return Object.entries(data).map(([k,v]) => ({...v, _key:k}));
};

// Crear admin Eider por defecto
get(usuariosRef).then(snap => {
    const data = snap.val() || {};
    const tieneAdmin = Object.values(data).some(u => u.usuario === 'eider');
    if (!tieneAdmin) {
        push(usuariosRef, { usuario: 'eider', password: '1234', rol: 'admin', nombre: 'Eider', creado: new Date().toLocaleDateString('es-ES') });
    }
});

window.firebaseReady = true;
