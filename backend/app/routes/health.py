from datetime import datetime, timezone

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.get("/health")
def get_health():
    return jsonify(
        {
            "status": "success",
            "message": "MoneyPilot backend is healthy",
            "serverTime": datetime.now(timezone.utc).isoformat().replace(
                "+00:00", "Z"
            ),
        }
    )
