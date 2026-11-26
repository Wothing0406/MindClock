from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse


def create_product_router() -> APIRouter:
    router = APIRouter()

    @router.get('/product', include_in_schema=False)
    def product() -> FileResponse:
        return FileResponse(Path(__file__).with_name('mobile.html'), headers={'Cache-Control': 'no-store'})

    @router.get('/product/style.css', include_in_schema=False)
    def style() -> FileResponse:
        return FileResponse(Path(__file__).with_name('product.css'), media_type='text/css', headers={'Cache-Control': 'no-store'})

    @router.get('/product/app.js', include_in_schema=False)
    def script() -> FileResponse:
        return FileResponse(Path(__file__).with_name('product.js'), media_type='application/javascript', headers={'Cache-Control': 'no-store'})

    return router
