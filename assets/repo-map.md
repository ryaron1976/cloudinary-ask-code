# Cloudinary repo map — pick your area

Each area lists the repos cloned for it. Don't see your repo? Choose
**"My repo isn't listed"** and name it — it will be cloned on demand
(any repo you have GitHub org access to).

> **Important — much core media logic lives in the monolith.** A lot of the
> image transformation, delivery, and URL-generation behavior is implemented in
> the **Core monolith** (`cloudinary`, `cld_core`, `cld_rails`), not in a
> product-named repo. If you're an **Image** PM especially — or your question is
> about how a transformation/delivery actually behaves — include the **Core
> monolith** group alongside your product's repos. When in doubt, pick your
> product area AND the monolith.

## Growth / Console / Onboarding
- CloudinaryLtd/console
- cloudinary/console-cool
- CloudinaryLtd/cld-web
- CloudinaryLtd/upload-widget-legacy

## Accounts / Permissions / Identity
- CloudinaryLtd/permission_management
- CloudinaryLtd/permission_enforcement
- CloudinaryLtd/permissions_pdp
- CloudinaryLtd/idp
- CloudinaryLtd/idp_service
- CloudinaryLtd/auth_service
- CloudinaryLtd/omniauth

## Billing & Monetization
- CloudinaryLtd/billing
- CloudinaryLtd/billing-events-consumer
- CloudinaryLtd/billing-dashboard-bff
- CloudinaryLtd/catalog-admin
- CloudinaryLtd/usage-reports
- CloudinaryLtd/arr-review

## Image
*Core transformation/delivery also lives in the Core monolith — include it too.*
- CloudinaryLtd/cld-image
- CloudinaryLtd/imageprocessing
- CloudinaryLtd/media-optimizer

## Video
- CloudinaryLtd/cld-video
- CloudinaryLtd/cloudinary-video-player
- CloudinaryLtd/cloudinary-video-player-studio
- CloudinaryLtd/ingestion_service
- CloudinaryLtd/live_video_ingestion

## Assets / DAM / MediaFlows
- CloudinaryLtd/assets-platform
- CloudinaryLtd/asset_management
- CloudinaryLtd/media-library-cms
- CloudinaryLtd/dynamic-asset-service
- CloudinaryLtd/dam-templates-service
- CloudinaryLtd/mediaflows-backend
- CloudinaryLtd/mediaflows-frontend

## Delivery / CDN / Upload
- CloudinaryLtd/cdn
- CloudinaryLtd/cld_url
- CloudinaryLtd/upload

## Trust & Safety / CSAM
- CloudinaryLtd/csam
- CloudinaryLtd/moderation-server

## Core monolith (cross-cutting)
- CloudinaryLtd/cloudinary
- CloudinaryLtd/cld_core
- CloudinaryLtd/cld_rails

## Admin tools
- CloudinaryLtd/cldadmin
- CloudinaryLtd/mediaflows-admin

## Public SDK reference
- cloudinary/account-provisioning-js
