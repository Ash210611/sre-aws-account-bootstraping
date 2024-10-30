import logging.config
from logger.combined_logger import CombinedLogger  # woodmac-python-logger


def get_logger(service_name,level='INFO'):
    """ Set up Woodmac standard logging. """

    app_name = "nlb_processing"
    component_name = "nlb_processing"

    log_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "wmjson": {
                "()": "logger.formatters.jsonformatter.CustomJsonFormatter",
                "format": "%(time)s %(level)s %(appName)s %(componentName)s %(name)s %(funcName)s %(lineno)s %(message)s",
                "datefmt": "%Y-%m-%dT%H:%M:%S",
            }
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": level,
                "formatter": "wmjson",
            }
        },
        "loggers": {
            "servicename": {
                "level": level,
                "handlers": ["console"],
                "propagate": False,
            },
            "": {"level": level, "handlers": ["console"]},
        },
    }

    logging.config.dictConfig(log_config)

    return CombinedLogger(
        service_name, app_name=app_name, component_name=component_name
    ).get_logger()
