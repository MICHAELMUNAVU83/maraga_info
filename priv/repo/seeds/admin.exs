alias MaragaInfo.Accounts
alias MaragaInfo.Accounts.User
alias MaragaInfo.Repo

email = "michaelmunavu83@gmail.com"

admin =
  case Repo.get_by(User, email: email) do
    nil ->
      {:ok, user} = Accounts.register_user(%{email: email, password: "123456"})
      user

    user ->
      user
  end

unless admin.is_admin do
  admin
  |> Ecto.Changeset.change(is_admin: true)
  |> Repo.update!()
end

IO.puts("Admin account ready: #{email}")
