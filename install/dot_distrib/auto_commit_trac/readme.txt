1. Активировать компонент CommitTicketUpdater через 
   админку или добавив в файл trac.ini следующие 
   строки:
       [components]
       tracopt.ticket.commit_updater.* = enabled
2. Установите commitupdate.patch для корректной обработки git
3. У Gitolite своя система организации хуков, правильным образом 
   прописанные они срабатывают на все репозитории им контролируемые, 
   а это как раз то что надо. Для этого под пользователем git создайте 
   файл ~/.gitolite/hooks/common/post-receive
   И в завершении активируйте этот хук выполнив следующие команды.
       sudo su git
       cd ~/.gitolite/hooks/common
       chmod 755 post-receive
       # Существует вариант что надо выполнить gl-setup
       gitolite setup --hooks-only
