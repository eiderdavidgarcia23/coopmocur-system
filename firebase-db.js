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
