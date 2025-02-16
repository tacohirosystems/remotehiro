{ pkgs, remotehiro-migrator-source }: pkgs.writeShellApplication {
  name = "remotehiro-migrator";

  runtimeInputs = with pkgs; [ sqitchSqlite sqlite remotehiro-migrator-source ];

  text = ''
    export SQITCH_CONFIG=${remotehiro-migrator-source}/sqitch.conf

    if [ "$1" = "init" ]; then
      echo "Initializing migrations..."
      sqitch --target remotehiro deploy 20260110124131_enriched_jobs_add_apply_email || true
      sqitch --target remotehiro-data deploy 20260110124908_jobs_alter_job_1_created_at || true
      sqitch --target remotehiro deploy 20260111093206_add_states || true
      sqitch --target remotehiro-data deploy 20260114015529_add_stack_influence_job_marketing || true
      sqitch --target remotehiro deploy 20260123102636_add_business_regions || true
      sqitch --target remotehiro-data deploy 20260131004620_add_buffer_be_job || true
    elif [ "$1" = "migrations" ]; then
      if [ "$2" = "up" ]; then
        echo "Running latest migrations..."
        sqitch --target remotehiro deploy
      elif [ "$2" = "down" ]; then
        echo "Reverting migrations..."
        sqitch --target remotehiro revert
      fi
    elif [ "$1" = "data-migrations" ]; then
      if [ "$2" = "up" ]; then
        sqitch --target remotehiro-data deploy
      elif [ "$2" = "down" ]; then
        sqitch --target remotehiro-data revert
      fi
    elif [ "$1" = "warehouse-migrations" ]; then
      if [ "$2" = "up" ]; then
        sqitch --target remotehiro-warehouse deploy
      elif [ "$2" = "down" ]; then
        sqitch --target remotehiro-warehouse revert
      fi
    fi
  '';
}
