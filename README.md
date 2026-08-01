# FXRP Vault

Ahorro simple sobre FXRP con valor en vivo (FTSOv2) y envío por link reclamable.

## Qué resuelve

Mandar valor a otra persona hoy requiere que sepas su dirección de wallet de antemano, o pasar por un exchange centralizado. FXRP Vault deja bloquear FXRP y generar un link: quien lo recibe conecta su propia wallet y lo reclama, sin que el emisor necesite conocer su dirección.

## Cómo usa Flare

- **FTSOv2**: valoriza el ahorro del usuario en USD en tiempo real, leyendo el feed XRP/USD directamente del oráculo enshrined de Flare (`getFeedById`, actualización cada ~1.8s).
- **FAssets (FXRP)**: el activo que se deposita y se envía es FXRP, el representante 1:1 de XRP en Flare via el Flare Data Connector.
- Red: Coston2 (testnet).

## Aviso de transparencia

El modo demo (`demoMode: true` en `fxrp-vault.html`) usa un **mock de FXRP y precios simulados con variación realista**, no lecturas on-chain reales, para poder grabar la demo sin depender del deploy final. Para ver la integración real con el FTSO y el contrato FAsset, cambiar `demoMode: false` en el frontend y apuntar a un `FXRPVault` deployado en Coston2 — ver sección "Deploy" abajo.

Como prueba independiente de que la integración con el FTSO es real y no solo un mock visual, `scripts/fetch-ftso.js` lee el precio de XRP/USD directamente del FTSOv2 en Coston2, sin depender del frontend ni del contrato propio.

## Estructura del repo

```
FXRPVault.sol       # Contrato: deposit, createSendLink, claim, getUsdValue (FTSOv2)
fxrp-vault.html      # Frontend: wallet connect, ticker en vivo, depósito, envío/reclamo por link
fetch-ftso.js        # Prueba de trabajo: lectura real del FTSOv2 en Coston2
README.md
```

## Deploy (pendiente al momento de este README)

1. Deployar un `MockFXRP` (ERC20 estándar) en Coston2 — ver sección "Aviso de transparencia".
2. Deployar `FXRPVault.sol` pasando la dirección del `MockFXRP` en el constructor.
3. Copiar la dirección del vault y el ABI generado a `CONFIG.vaultAddress` / `CONFIG.vaultAbi` en `fxrp-vault.html`.
4. Poner `demoMode: false`.
5. Verificar el contrato en el explorer de Coston2.

## Roadmap post-hackathon

- Reemplazar `MockFXRP` por el contrato real de FAssets cuando esté disponible en la red objetivo.
- Meta de ahorro configurable por el usuario (actualmente fija en $200 para la demo).
- Notificación al receptor cuando se genera un link dirigido a su dirección conocida.
