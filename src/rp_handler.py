import runpod
import time


def handler(event):
    """
    This function processes incoming requests to your Serverless endpoint.

    Args:
        event (dict): Contains the input data and request metadata

    Returns:
        Any: The result to be returned to the client
    """

    # Extract input data
    print(f"Worker Start")
    print(f"event: {event}")
    file = event.get("file")
    print(f"Received file: {file.filename}")

    return file.filename


# Start the Serverless function when the script is run
if __name__ == '__main__':
    runpod.serverless.start({'handler': handler})
