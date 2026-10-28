# Scout Agents — Video Editor

Plantilla para crear agentes de **edición de video y motion graphics** que comparten el mismo conocimiento y las mismas skills, y que funcionan en cualquier herramienta compatible con `AGENTS.md` / `SKILL.md`: Claude Code, Codex, OpenCode y similares.

El agente:

1. **Conoce la marca antes de editar.** En la primera sesión pregunta por la marca del usuario (nombre, tono, colores, tipografías, logo, plataformas, referencias) y guarda la respuesta en `brand/profile.md`.
2. **Prepara su propio entorno.** Verifica e instala FFmpeg, Node, Chromium, Python y las dependencias de transcripción y recorte.
3. **Pide las sesiones y conexiones que necesita.** Solicita solo las credenciales requeridas para la tarea (proveedor de IA, Google Drive) y deja las opcionales (HeyGen, ElevenLabs) para cuando se usen.
4. **Edita con un pipeline probado.** Usa FFmpeg para footage real y Hyperframes (HTML/CSS/JS + GSAP renderizado en Chromium) para motion; siempre entrega un borrador antes del final.

## Inicio rápido

1. Clona este repo y abre una sesión de tu agente en la raíz.
2. Copia el prompt de [`prompts/bootstrap.md`](prompts/bootstrap.md) y pégalo en Claude, Codex, OpenCode, etc.
3. Responde las preguntas de marca y autoriza las conexiones que te pida.
4. Pide tu primer video: *"Haz un reel 9:16 de 30 s con este clip: …"*.

## Estructura

```
.
├── README.md               # Este archivo
├── AGENTS.md               # Instrucciones del agente: rol, pipeline, reglas, credenciales
├── CLAUDE.md               # Importa AGENTS.md para Claude Code
├── .env.example            # Nombres de credenciales (nunca valores)
├── prompts/
│   └── bootstrap.md        # Prompt para pegar: instala requisitos, pide marca y conexiones
├── skills/                 # Fuente canónica de skills (una carpeta por skill con SKILL.md)
├── scripts/
│   ├── install.sh          # Instala dependencias del sistema y del entorno de reels
│   ├── doctor.sh           # Verifica herramientas, entornos y credenciales
│   └── link-skills.sh      # Enlaza skills/ en .claude/, .agents/ y .opencode/
├── brand/
│   ├── profile.template.md # Plantilla del perfil de marca
│   └── profile.md          # Perfil real de la marca (generado, ignorado por git)
├── memory/                 # Memoria del agente: index.md, misc.md, important/ (ignorada por git)
├── jobs/                   # Trabajos: jobs/<job>/{src,work,out} (ignorado por git)
└── base/
    └── knowledge.md        # Investigación fuente (ignorada por git)
```

`skills/` es la única fuente de verdad. Las carpetas de cada herramienta (`.claude/skills`, `.agents/skills`, `.opencode/skill`) se generan con `scripts/link-skills.sh` y están en `.gitignore`.

## Skills

### Edición (heredadas del agente Video Editor)

| Skill | Qué hace |
| --- | --- |
| `hyperframes` | Punto de entrada para proyectos de motion en HTML/CSS/JS. |
| `hyperframes-core` | Composición, timing, clips, tracks y render determinista. |
| `hyperframes-animation` | Reglas de animación, blueprints de escena, transiciones y adaptadores (GSAP). |
| `hyperframes-creative` | Dirección visual, tipografía, paletas, narración y ritmo. |
| `hyperframes-cli` | Init, lint, inspect, preview y render; render en la nube opcional. |
| `ffmpeg` | Cortes, conversión, escalado, compresión, audio y exportación. |
| `video-editing` | Flujo general de footage crudo a edición ensamblada. |
| `five-pass-reel-edit` | Reels de cabeza parlante en cinco pasadas con revisión entre cada una. |
| `reel-motion-effects` | 17 efectos sincronizados por palabra (gráficas, checklists, órbitas, fondos). |
| `brag` | Videos de lanzamiento de 15–25 s con Hyperframes; narración opcional con Kokoro. |
| `brag-slim` | Versión ligera de `brag` sin voz, solo con herramientas locales. |
| `self-improvement` | Registra errores, correcciones y mejores enfoques para futuros trabajos. |

### Arranque (nuevas)

| Skill | Qué hace |
| --- | --- |
| `brand-onboarding` | Entrevista de marca en la primera sesión; crea y actualiza `brand/profile.md`. |
| `environment-setup` | Detecta el sistema, instala requisitos y repara el entorno Python de reels. |
| `connections-setup` | Pide y verifica sesiones: proveedor de IA, Google Drive (rclone) y servicios opcionales. |

## Pipeline de edición

1. Leer `memory/index.md`, `brand/profile.md` y las notas de pipelines probados.
2. Elegir formato: **9:16** para redes, **16:9** para landing y YouTube largo.
3. Footage real → FFmpeg. Motion → Hyperframes + GSAP → Chromium → MP4.
4. Reels de cabeza parlante → cinco pasadas: transcribir y recortar, quitar fondo, subtítulos por palabra, motion graphics, mezcla de sonido. Preview y aprobación entre pasadas.
5. Borrador antes del final: hook en ≤ 1.2 s, título en el primer frame, subtítulos, cortes limpios entre palabras.
6. QA con FFprobe y revisión visual. Objetivo del reel: 1080×1920, 30 fps, H.264/AAC, −14 LUFS integrados, true peak < −1 dB, `faststart`.
7. Guardar en `jobs/<job>/out/`, subir a `gdrive:<Carpeta>/<YYYY-MM-DD>/`, verificar tamaño y devolver el enlace.

Fuera de alcance: estrategia, copywriting amplio, calendarización y publicación en redes.

## Credenciales

Los valores van en `.env` o en el gestor de credenciales de la herramienta, **nunca** en prompts ni en git.

| Nivel | Credencial | Cuándo |
| --- | --- | --- |
| Requerida | Proveedor de IA (`ANTHROPIC_API_KEY` o la sesión de tu herramienta) | Planificación y decisiones de edición. |
| Requerida | Google Drive OAuth vía `rclone` (remote `gdrive:`) | Leer assets y entregar videos. |
| Alternativa | `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `GOOGLE_API_KEY`, login de Codex | Solo si eliges ese proveedor. |
| Opcional | `HEYGEN_API_KEY` / `HYPERFRAMES_API_KEY` / `HEYGEN_ACCESS_TOKEN` | Solo para `hyperframes cloud render`. |
| Opcional | `ELEVENLABS_API_KEY` | Solo para voz con ElevenLabs pedida explícitamente. |
| Opcional | Cuentas de AWS o Google Cloud | Solo para render en Lambda o Cloud Run. |

FFmpeg, Chromium, GSAP, Hyperframes local, la transcripción Whisper local y el matting ONNX **no** requieren API keys, aunque sí red para descargar paquetes y modelos.

## Requisitos del sistema

- FFmpeg y FFprobe
- Node.js ≥ 24 con npm/npx
- Chromium (o Chrome) para Playwright/Hyperframes
- Python ≥ 3.10 con un venv dedicado para reels: `faster-whisper`, `onnxruntime`, `numpy`, `opencv-python`
- `rclone` y Git

`scripts/doctor.sh` verifica todo lo anterior. Una API key no arregla un venv roto: si el doctor reporta fallas en transcripción o matting, ejecuta `scripts/install.sh`.

## Crear un agente nuevo

Cada agente es una copia de este repo con su propia marca y memoria:

```bash
git clone <este-repo> mi-agente && cd mi-agente
./scripts/link-skills.sh
```

Luego pega el prompt de `prompts/bootstrap.md`. El conocimiento y las skills son compartidos; `brand/profile.md`, `memory/` y `jobs/` son propios de cada instancia.
