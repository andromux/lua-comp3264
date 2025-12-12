# lua-comp3264
allow compiling ur lua files on both arch
GitHub Actions workflow optimizado para compilar tus archivos Lua 5.3.X para ambas arquitecturas (32 y 64 bits):

## 📁 Estructura recomendada para tu repositorio:

```
tu-repositorio/
├── .github/
│   └── workflows/
│       └── compile-lua.yml    # ← Aquí va el workflow
├── archivo1.lua               # Tus archivos Lua fuente
├── archivo2.lua
├── main.lua
└── README.md
```

## Características del workflow:

✅ **Compila para 32 y 64 bits** en paralelo usando matrix strategy
✅ **Usa Lua 5.3.6** específicamente
✅ **Stripping automático** con `luac -s` (elimina debug info)
✅ **Nombrado automático**: `archivo-32.lua` y `archivo-64.lua`
✅ **Crea carpetas separadas**: `compilados_32/` y `compilados_64/`
✅ **Genera archivos .tar.gz** comprimidos
✅ **Sube artefactos** que puedes descargar por 30 días
✅ **Crea releases automáticos** cuando haces un tag
✅ **Manejo de errores** con logs detallados

## Cómo usar:

1. **Crea el archivo del workflow**:
   ```bash
   mkdir -p .github/workflows
   # Copia el contenido del artifact en .github/workflows/compile-lua.yml
   ```

2. **Coloca tus archivos .lua en la raíz** del repositorio

3. **Haz commit y push**:
   ```bash
   git add .
   git commit -m "Add Lua compilation workflow"
   git push
   ```

4. **Descarga los compilados**:
   - Ve a la pestaña "Actions" en GitHub
   - Selecciona el workflow ejecutado
   - Descarga los artifacts: `compilados-lua-32bits` y `compilados-lua-64bits`

## Para crear un release automático:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Esto creará un release con los archivos `.tar.gz` adjuntos.

## Personalización:

Si tus archivos Lua están en otra carpeta, cambia esta línea:
```yaml
for archivo in *.lua; do
```

Por:
```yaml
for archivo in carpeta_origen/*.lua; do
```
