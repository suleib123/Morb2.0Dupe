#Login 


class Login(discord.ui.Modal):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)

        self.add_item(discord.ui.InputText(label="Authorization Code."))


    async def callback(self, interaction: discord.Interaction):
        Data_Check = await user_data.find_one({"UserId": interaction.user.id})
        if Data_Check is None:
            try:
                
                HeaderData = {
                    "Content-Type": f"application/x-www-form-urlencoded",
                    "Authorization": f"basic MzQ0NmNkNzI2OTRjNGE0NDg1ZDgxYjc3YWRiYjIxNDE6OTIwOWQ0YTVlMjVhNDU3ZmI5YjA3NDg5ZDMxM2I0MWE="
                }
                LoginData = f"grant_type=authorization_code&code={self.children[0].value}"
                LoginRequest = requests.post("https://account-public-service-prod.ol.epicgames.com/account/api/oauth/token",headers=HeaderData,data=LoginData)
                
                display_name = LoginRequest.json()['displayName']
                accountId = LoginRequest.json()['account_id']
                access_code = LoginRequest.json()['access_token']
                
                headers = {'Authorization': f'Bearer {access_code}'}
                response = requests.post(url=f'https://account-public-service-prod.ol.epicgames.com/account/api/public/account/{accountId}/deviceAuth', headers=headers)
                device_id, secret = response.json()['deviceId'], response.json()['secret']


                DataInsert = {
                    "UserId": interaction.user.id, 
                    "AccessToken": access_code, 
                    "AccountId": accountId, 
                    "DisplayName": display_name,
                    "DeviceId": device_id, 
                    "Secret": secret
                }

                await user_data.insert_one(DataInsert)
                
                avatar = await FetchAvatarUser(interaction.user.id)
                


                embed = discord.Embed(
                    title=f"You are now logged in as, `{display_name}`",
                    description="You have been added to our databases.",
                    colour= discord.Colour.brand_green()
                )
                embed.set_thumbnail(url=avatar)

                    
                await interaction.response.send_message(embeds=[embed])

            except:
                await interaction.respond.send_message("Authorization Code Expired.")
                
        else:
            embed = discord.Embed(title="Logged In Already.",description=f"You are already logged in as, `{Data_Check['DisplayName']}`",colour=discord.Colour.green())
            await interaction.response.send_message(embeds=[embed]) 



class LoginGUI(discord.ui.View):  # Create a class called MyView that subclasses discord.ui.View

    @discord.ui.button(label="Submit", style=discord.ButtonStyle.green)
    async def button_callback(self, button, interaction: discord.Interaction):
        modal = Login(title="Authorization Code")
        await interaction.response.send_modal(modal)


@bot.slash_command(description="Login to your fortnite account.")
async def login(ctx):
    GUI = LoginGUI()
    Add_Component = GUI.add_item(discord.ui.Button(label="Authorization Code", style=discord.ButtonStyle.link, url="https://www.epicgames.com/id/api/redirect?clientId=3446cd72694c4a4485d81b77adbb2141&responseType=code"))
    embed = discord.Embed(
        title="**`Login Process.`**",
        description="To login follow these steps to login :\n\n`1.` Click The Button Named Authorization Code\n\n`2.` Copy Your Authorization Code\n\n`3.` Paste Your Authorization Code in Submit\n\nWrong Account or authorizationCode shows null try [this](https://www.epicgames.com/id/login?redirectUrl=https%3A%2F%2Fwww.epicgames.com%2Fid%2Fapi%2Fredirect%3FclientId%3D3446cd72694c4a4485d81b77adbb2141%26responseType%3Dcode)",
        colour = discord.Colour.brand_green(),
    )
    await ctx.respond(embed=embed, view=GUI)
    
