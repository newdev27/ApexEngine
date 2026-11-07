import os, json, time, random
import discord
from discord import app_commands, ui
from github import Github
from dotenv import load_dotenv

load_dotenv()

DISCORD_TOKEN  = os.getenv("DISCORD_TOKEN")
GITHUB_TOKEN   = os.getenv("GITHUB_TOKEN")
GITHUB_REPO    = os.getenv("GITHUB_REPO")        # "newdev27/ApexEngine"
BUYER_ROLE_ID  = int(os.getenv("BUYER_ROLE_ID"))  # role given on redeem
OWNER_ID       = int(os.getenv("OWNER_ID"))       # your Discord user ID
SCRIPT_LOADSTRING = os.getenv("SCRIPT_LOADSTRING") # the loadstring URL
KEYS_FILE      = "keys.json"
SALT           = "AX_br27_$3cr3t_2k25"
CHARS          = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

# --- Key validation (mirrors ApexEngine.lua logic) ---

TIER_CODES = {"MN","HR","DY","FR","WK","MO","YR","LT"}

def make_checksum(body: str) -> str:
    h = 5381
    for c in body + SALT:
        h = ((h * 33) + ord(c)) % 1048576
    c1 = CHARS[h % len(CHARS)]
    c2 = CHARS[(h // len(CHARS)) % len(CHARS)]
    return c1 + c2

def fetch_keys():
    repo = Github(GITHUB_TOKEN).get_repo(GITHUB_REPO)
    f    = repo.get_contents(KEYS_FILE)
    return json.loads(f.decoded_content), f.sha

def push_keys(data, sha, msg="Update key"):
    repo = Github(GITHUB_TOKEN).get_repo(GITHUB_REPO)
    repo.update_file(KEYS_FILE, msg, json.dumps(data, indent=2), sha)

def validate_and_bind(key: str, discord_id: str):
    """Returns (ok: bool, message: str)"""
    parts = key.upper().split("-")
    if len(parts) != 4 or parts[0] != "APEX" or len(parts[1]) != 6 or len(parts[2]) != 6 or len(parts[3]) != 2:
        return False, "❌ Invalid key format."

    if parts[1][:2] not in TIER_CODES:
        return False, "❌ Invalid tier code."

    body = f"APEX-{parts[1]}-{parts[2]}"
    if make_checksum(body) != parts[3]:
        return False, "❌ Key checksum failed."

    try:
        data, sha = fetch_keys()
    except Exception as e:
        return False, f"❌ Could not reach key server: {e}"

    entry = data["keys"].get(key.upper())
    if not entry:
        return False, "❌ Key not found."
    if entry["blocked"]:
        return False, "❌ Key is blocked."
    if entry["expires_at"] and int(time.time()) > entry["expires_at"]:
        entry["blocked"] = True
        push_keys(data, sha, "Auto-block expired key")
        return False, "❌ Key has expired."
    if entry["hwid"] and entry["hwid"] != discord_id:
        entry["blocked"] = True
        push_keys(data, sha, "Block shared key")
        return False, "❌ Key is locked to another user and has been blocked."

    # Bind HWID if first use
    if not entry["hwid"]:
        entry["hwid"] = discord_id
        push_keys(data, sha, f"Bind key to {discord_id}")

    return True, entry["tier"]

# --- UI Components ---

class RedeemModal(ui.Modal, title="Redeem Your Key"):
    key = ui.TextInput(label="Enter your Apex Engine key", placeholder="APEX-XXXXXX-XXXXXX-XX", min_length=20, max_length=25)

    async def on_submit(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        discord_id = str(interaction.user.id)
        ok, result = validate_and_bind(self.key.value.strip(), discord_id)

        if not ok:
            await interaction.followup.send(result, ephemeral=True)
            return

        # Give buyer role
        role = interaction.guild.get_role(BUYER_ROLE_ID)
        if role and role not in interaction.user.roles:
            await interaction.user.add_roles(role)

        await interaction.followup.send(
            f"✅ Key redeemed! Tier: **{result.upper()}**\nYou've been given the buyer role.", ephemeral=True
        )

class ControlPanelView(ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    @ui.button(label="Redeem Key", style=discord.ButtonStyle.green, custom_id="redeem_key", emoji="🔑")
    async def redeem(self, interaction: discord.Interaction, button: ui.Button):
        await interaction.response.send_modal(RedeemModal())

    @ui.button(label="Get Script", style=discord.ButtonStyle.blurple, custom_id="get_script", emoji="📜")
    async def get_script(self, interaction: discord.Interaction, button: ui.Button):
        role = interaction.guild.get_role(BUYER_ROLE_ID)
        if role not in interaction.user.roles:
            await interaction.response.send_message("❌ Redeem a valid key first.", ephemeral=True)
            return
        try:
            await interaction.user.send(
                f"**Apex Engine Script**\n```lua\n{SCRIPT_LOADSTRING}\n```"
            )
            await interaction.response.send_message("✅ Script sent to your DMs!", ephemeral=True)
        except discord.Forbidden:
            await interaction.response.send_message("❌ Couldn't DM you. Enable DMs from server members.", ephemeral=True)

    @ui.button(label="Get Role", style=discord.ButtonStyle.grey, custom_id="get_role", emoji="👤")
    async def get_role(self, interaction: discord.Interaction, button: ui.Button):
        role = interaction.guild.get_role(BUYER_ROLE_ID)
        if role in interaction.user.roles:
            await interaction.response.send_message("✅ You already have the buyer role.", ephemeral=True)
        else:
            await interaction.response.send_message("❌ Redeem a valid key first to get your role.", ephemeral=True)

# --- Bot setup ---

intents = discord.Intents.default()
intents.members = True
client = discord.Client(intents=intents)
tree   = app_commands.CommandTree(client)

@tree.command(name="panel", description="Send the Apex Engine control panel")
async def panel(interaction: discord.Interaction):
    if interaction.user.id != OWNER_ID:
        await interaction.response.send_message("❌ Owner only.", ephemeral=True)
        return

    embed = discord.Embed(
        title="Apex Engine Control Panel",
        description=(
            "This control panel is for the project: **Apex Engine**\n\n"
            "If you're a buyer, click on the buttons below to redeem your key, get the script or get your role."
        ),
        color=0x5865F2
    )
    embed.set_footer(text="Apex Engine • Powered by newdev27")

    await interaction.channel.send(embed=embed, view=ControlPanelView())
    await interaction.response.send_message("✅ Panel sent.", ephemeral=True)

@client.event
async def on_ready():
    client.add_view(ControlPanelView())  # re-register persistent view on restart
    await tree.sync()
    print(f"[ApexEngine Bot] Ready as {client.user}")

client.run(DISCORD_TOKEN)
