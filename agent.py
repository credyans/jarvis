import os
import sys
from dotenv import load_dotenv

# Ensure the script directory is in sys.path for portable runtimes
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from livekit import agents
from livekit.agents import AgentServer, AgentSession, Agent, room_io
from livekit.plugins import (
    google,
    ai_coustics,
)
from prompts import AGENT_INSTRUCTION, SESSION_INSTRUCTION

load_dotenv(".env.local")

class Assistante(Agent):
    def __init__(self) -> None:
        super().__init__(instructions=AGENT_INSTRUCTION)

server = AgentServer()

@server.rtc_session(agent_name="my-agent")
async def my_agent(ctx: agents.JobContext):
    session = AgentSession(
        llm=google.beta.realtime.RealtimeModel(
            model="gemini-2.0-flash-exp",
            voice="Puck"
        )
    )

    await session.start(
        room=ctx.room,
        agent=Assistante(),
        room_options=room_io.RoomOptions(
            audio_input=room_io.AudioInputOptions(
                noise_cancellation=ai_coustics.audio_enhancement(model=ai_coustics.EnhancerModel.QUAIL_VF_S),
            ),
        ),
    )

    await session.generate_reply(
        instructions=SESSION_INSTRUCTION
    )


if __name__ == "__main__":
    agents.cli.run_app(server)
