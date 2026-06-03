let inventario = JSON.parse(localStorage.getItem('coopmocur_inventario')) || [];
let historial = JSON.parse(localStorage.getItem('coopmocur_historial')) || [];

// Esperar a que el HTML esté totalmente cargado en el celular
window.onload = function() {
    pintarInventario();
    
    const fechaDiv = document.getElementById('fecha-actual');
    if (fechaDiv) {
        fechaDiv.innerText = new Date().toLocaleDateString('es-ES', {
            weekday: 'short', day: 'numeric', month: 'short'
        }).toUpperCase();
    }
};

function irAPestaña(pestañaDestino) {
    const vistas = ['inventario', 'entradas', 'ventas', 'historial'];
    vistas.forEach(vista => {
        document.getElementById(`vista-${vista}`).classList.add('hidden');
        document.getElementById(`tab-${vista}`).className = "w-full py-3.5 text-slate-500 hover:text-blue-700";
    });
    
    document.getElementById(`vista-${pestañaDestino}`).classList.remove('hidden');
    document.getElementById(`tab-${pestañaDestino}`).className = "w-full py-3.5 text-blue-700 border-b-4 border-blue-700 font-black";
    
    if (pestañaDestino === 'inventario') pintarInventario();
    if (pestañaDestino === 'entradas' || pestañaDestino === 'ventas') recargarListasDesplegables();
    if (pestañaDestino === 'historial') pintarHistorial();
}

function respaldarEnMemoria() {
    localStorage.setItem('coopmocur_inventario', JSON.stringify(inventario));
    localStorage.setItem('coopmocur_historial', JSON.stringify(historial));
}

function mostrarModal(visible) {
    const modal = document.getElementById('modal-nueva-pieza');
    if (visible) modal.classList.remove('hidden');
    else modal.classList.add('hidden');
}

function pintarInventario() {
    const contenedor = document.getElementById('contenedor-stock');
    if (!contenedor) return;
    contenedor.innerHTML = '';
    
    if (inventario.length === 0) {
        contenedor.innerHTML = `<div class="text-center py-10 bg-white rounded-2xl border border-dashed border-slate-300"><p class="text-sm text-slate-400 font-medium">No hay repuestos en el sistema.</p></div>`;
        return;
    }
    
    inventario.forEach(pieza => {
        const esBajoStock = pieza.stock <= 3;
        const tarjetaEstilo = esBajoStock ? 'bg-red-50 border-red-200' : 'bg-white border-slate-200';
        const badgeEstilo = esBajoStock ? 'bg-red-600 text-white' : 'bg-slate-800 text-slate-200';
        
        contenedor.innerHTML += `
            <div class="p-4 rounded-xl border shadow-xs flex justify-between items-center ${tarjetaEstilo}">
                <div>
                    <h3 class="font-extrabold text-sm text-slate-800">${pieza.nombre}</h3>
                    <div class="flex gap-2 items-center">
                        <span class="text-[10px] font-mono font-bold bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded border border-slate-200">REF: ${pieza.codigo}</span>
                        <span class="text-xs font-bold text-blue-700">$${Number(pieza.precio).toLocaleString()}</span>
                    </div>
                </div>
                <div class="text-right">
                    <span class="text-xs font-black px-2.5 py-1 rounded-md ${badgeEstilo}">${pieza.stock} U</span>
                </div>
            </div>`;
    });
}

function buscarRepuesto() {
    const termino = document.getElementById('buscador').value.toLowerCase();
    const tarjetas = document.getElementById('contenedor-stock').children;
    Array.from(tarjetas).forEach(tarjeta => {
        if (tarjeta.textContent.toLowerCase().includes(termino)) tarjeta.classList.remove('hidden');
        else tarjeta.classList.add('hidden');
    });
}

function agregarRepuestoCatalogo(e) {
    e.preventDefault();
    const nombre = document.getElementById('reg-nombre').value.trim();
    const codigo = document.getElementById('reg-codigo').value.trim().toUpperCase();
    const stock = parseInt(document.getElementById('reg-stock').value) || 0;
    const precio = parseFloat(document.getElementById('reg-precio').value) || 0;
    
    if (inventario.some(p => p.codigo === codigo)) {
        alert("❌ Esa Referencia ya existe.");
        return;
    }
    
    inventario.push({ id: Date.now(), nombre, codigo, stock, precio });
    anotarHistorial(codigo, 'Registro Inicial 🔩', stock, `Agregado con precio base de $${precio.toLocaleString()}`);
    respaldarEnMemoria();
    mostrarModal(false);
    document.getElementById('form-nuevo-repuesto').reset();
    pintarInventario();
}

function recargarListasDesplegables() {
    const selectEntrada = document.getElementById('select-entrada-pieza');
    const selectVenta = document.getElementById('select-venta-pieza');
    let opciones = '<option value="" disabled selected>Elige un repuesto...</option>';
    
    inventario.forEach(pieza => {
        opciones += `<option value="${pieza.id}">${pieza.nombre} [${pieza.codigo}] - Stock: ${pieza.stock}</option>`;
    });
    
    if (selectEntrada) selectEntrada.innerHTML = opciones;
    if (selectVenta) selectVenta.innerHTML = opciones;
}

function detectarPrecioYStockSugerido() {
    const idPieza = document.getElementById('select-venta-pieza').value;
    const pieza = inventario.find(p => p.id == idPieza);
    const divAlerta = document.getElementById('notificacion-stock');
    if (pieza) {
        document.getElementById('input-venta-precio').value = pieza.precio;
        divAlerta.classList.remove('hidden');
        divAlerta.innerText = `Máximo disponible en COOPMOCUR: ${pieza.stock} unidades.`;
    }
}

function procesarEntrada(e) {
    e.preventDefault();
    const idPieza = document.getElementById('select-entrada-pieza').value;
    const cantidad = parseInt(document.getElementById('input-entrada-cantidad').value);
    const costo = parseFloat(document.getElementById('input-entrada-costo').value);
    const pieza = inventario.find(p => p.id == idPieza);
    
    if (pieza) {
        pieza.stock += cantidad;
        anotarHistorial(pieza.codigo, 'Entrada 📥', cantidad, `Costo total: $${(cantidad * costo).toLocaleString()}`);
        respaldarEnMemoria();
        document.getElementById('form-entrada').reset();
        alert("✅ Stock actualizado con éxito.");
        irAPestaña('inventario');
    }
}

// Vinculación de los eventos de los formularios del HTML
document.addEventListener('submit', function(e) {
    if (e.target && e.target.id === 'form-nuevo-repuesto') agregarRepuestoCatalogo(e);
    if (e.target && e.target.id === 'form-entrada') procesarEntrada(e);
    if (e.target && e.target.id === 'form-venta') procesarVenta(e);
});

function procesarVenta(e) {
    e.preventDefault();
    const idPieza = document.getElementById('select-venta-pieza').value;
    const cantidad = parseInt(document.getElementById('input-venta-cantidad').value);
    const precioVenta = parseFloat(document.getElementById('input-venta-precio').value);
    const pieza = inventario.find(p => p.id == idPieza);
    
    if (pieza) {
        if (pieza.stock < cantidad) {
            alert(`❌ Stock insuficiente en COOPMOCUR. Solo hay: ${pieza.stock}`);
            return;
        }
        pieza.stock -= cantidad;
        anotarHistorial(pieza.codigo, 'Venta 💸', cantidad, `Total cobrado: $${(cantidad * precioVenta).toLocaleString()}`);
        respaldarEnMemoria();
        document.getElementById('form-venta').reset();
        document.getElementById('notificacion-stock').classList.add('hidden');
        alert("🎉 Venta registrada.");
        irAPestaña('inventario');
    }
}

function anotarHistorial(codigo, tipo, cantidad, detalle) {
    historial.unshift({ fecha: new Date().toLocaleString('es-ES'), codigo, tipo, cantidad, detalle });
}

function pintarHistorial() {
    const contenedor = document.getElementById('contenedor-historial');
    if (!contenedor) return;
    contenedor.innerHTML = '';
    
    if (historial.length === 0) {
        contenedor.innerHTML = `<p class="text-center py-10 text-xs text-slate-400">Sin movimientos registrados.</p>`;
        return;
    }
    
    historial.forEach(mov => {
        contenedor.innerHTML += `
            <div class="p-3 bg-white rounded-xl border border-slate-200 text-xs space-y-1 shadow-xs">
                <div class="flex justify-between items-center"><span class="font-bold border px-2 py-0.5 rounded">${mov.tipo}</span><span class="text-slate-400 font-mono text-[10px]">${mov.fecha}</span></div>
                <p class="text-slate-700 font-semibold">Ref: ${mov.codigo} | Cantidad: ${mov.cantidad}</p>
                <p class="text-slate-400 italic text-[11px]">${mov.detalle}</p>
            </div>`;
    });
}

function vaciarKardex() {
    if (confirm("¿Borrar todo el historial?")) { historial = []; respaldarEnMemoria(); pintarHistorial(); }
}

