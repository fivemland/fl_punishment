<script>
  import { locale, locales, _ } from 'svelte-i18n';

  import Loading from './Loading.svelte';

  const buttons = ['comserv', 'jail', 'ban'];

  let visible = false;
  let selectedTab = 'comserv';

  let users = [];
  let search = '';

  $: filteredUsers = users.filter((user) => user.name.toLowerCase().includes(search.toLowerCase()));

  async function selectTab(name) {
    if (selectedTab === name) return;

    selectedTab = name;

    users = [];

    const response = await fetch(`https://${GetParentResourceName()}/requestUsers`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
      }),
    });

    const responseJson = await response.json();
    if (responseJson.error) return (users = []);

    users = [...responseJson.users];
  }

  window.addEventListener('message', ({ data }) => {
    if (data.adminPanel !== undefined) {
      visible = data.adminPanel;
      selectedTab = false;
      if (visible) selectTab('comserv');
    }
  });

  function close() {
    visible = false;
    fetch(`https://${GetParentResourceName()}/closeAdminPanel`);
  }

  async function remove(user) {
    const response = await fetch(`https://${GetParentResourceName()}/removeUser`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
        identifier: user.identifier,
      }),
    });

    const responseJson = await response.json();

    users = responseJson.users;
  }

  let userInfo = false;

  async function requestUserData(user) {
    userInfo = false;

    const response = await fetch(`https://${GetParentResourceName()}/requestUserData`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
        identifier: user.identifier,
      }),
    });

    const responseJson = await response.json();

    if (responseJson.error) return (userInfo = responseJson.error);

    userInfo = responseJson.userInfo;
    userInfo[selectedTab] = JSON.parse(userInfo[selectedTab]);
    userInfo.accounts = JSON.parse(userInfo.accounts);
  }

  function formatDate(timestamp) {
    return new Date((timestamp || 0) * 1000).toLocaleString('en-GB');
  }
</script>

{#if visible}
  <main class="bg-slate-700 rounded-lg w-2/5 p-2">
    <div class="flex justify-between items-center text-xl mb-2">
      {$_(selectedTab)}

      <div class="flex gap-4 items-center">
        <label class="text-warning text-sm" for="settings-modal">
          <i class="fa-solid fa-gear" />
        </label>

        <button on:click={close} class="text-error">
          <i class="fa-solid fa-xmark" />
        </button>
      </div>
    </div>
    <div class="flex justify-between">
      <div class="flex">
        {#each buttons as button}
          <button on:click={() => selectTab(button)} class="btn btn-sm btn-info mx-1">
            {$_(button)}
          </button>
        {/each}
      </div>
      <div class="mb-2">
        <input
          bind:value={search}
          disabled={users.length <= 0}
          placeholder={$_('search_placeholder')}
          type="text"
          class="input input-bordered input-sm w-full"
        />
      </div>
    </div>

    <div class="max-h-96 overflow-y-auto">
      {#if search.length > 0 && filteredUsers.length <= 0}
        <div class="text-center text-warning text-lg mt-4">
          {$_('search_result')}
          <br />
          {$_('users_not_found')}
        </div>
      {/if}

      {#if users.length <= 0}
        <div class="text-center text-warning text-lg mt-4">{$_('users_not_found')}</div>
      {:else}
        {#each filteredUsers as user}
          {#if user}
            <div class="grid grid-flow-col gap-2 items-center bg-slate-800 p-2 rounded-md border-b border-gray-900">
              <div class="w-40">{user.name || $_('unknown')}</div>
              <div class="w-60 text-center">
                <div class="tooltip tooltip-left" data-tip={$_('reason')}>
                  {user[selectedTab].reason || $_('unknown')}
                </div>
              </div>
              <div>
                <div class="tooltip tooltip-right" data-tip={$_('count')}>
                  {#if selectedTab === 'ban'}
                    {parseInt(user[selectedTab].count || 0) === 0 ? $_('infinity') : user[selectedTab].count + ' ' + $_('days')}
                  {:else}
                    {user[selectedTab].count || 0}/{user[selectedTab].all || 0}{selectedTab === 'jail' ? ' ' + $_('minutes') : ''}
                  {/if}
                </div>
              </div>
              <div class="ml-auto">
                <!-- svelte-ignore a11y-click-events-have-key-events -->
                <label on:click={() => requestUserData(user)} class="btn btn-sm btn-circle btn-primary modal-button" for="info-modal">
                  <i class="fa-solid fa-info" />
                </label>

                <button on:click={() => remove(user)} class="btn btn-sm btn-circle btn-error">
                  <i class="fa-solid fa-trash-can" />
                </button>
              </div>
            </div>
          {/if}
        {/each}
      {/if}
    </div>
  </main>
{/if}

<input type="checkbox" id="info-modal" class="modal-toggle" />
<div class="modal">
  <div class="modal-box bg-gray-800">
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <label on:click={(userInfo = false)} for="info-modal" class="btn btn-sm btn-circle absolute right-2 top-2">
      <i class="fa-solid fa-xmark" />
    </label>
    <h3 class="font-bold text-lg">{$_('user_informations')}</h3>

    {#if userInfo === undefined || userInfo === false}
      <div class="text-center">
        <Loading />
      </div>
    {:else if typeof userInfo === 'string'}
      <div class="text-center text-error text-lg mt-3">{userInfo}</div>
    {:else}
      <table class="table table-compact w-full mt-3 py-4">
        <tbody>
          <tr>
            <td colspan="2" class="font-bold text-center">{$_('user_informations')}</td>
          </tr>

          <tr>
            <td>{$_('identifier')}</td>
            <td class="text-right">{userInfo.identifier || 'Unknown'}</td>
          </tr>
          <tr>
            <td>{$_('char_name')}</td>
            <td class="text-right">{userInfo.firstname || 'Unknown'} {userInfo.lastname || 'Unknown'}</td>
          </tr>
          <tr>
            <td>{$_('job')}</td>
            <td class="text-right">{userInfo.job || 'Unknown'}</td>
          </tr>
          <tr>
            <td>{$_('money')}</td>
            <td class="text-right">{userInfo.accounts.money}$</td>
          </tr>
          <tr>
            <td>{$_('bank_money')}</td>
            <td class="text-right">{userInfo.accounts.bank}$</td>
          </tr>
          <tr>
            <td>{$_('dirt_money')}</td>
            <td class="text-right">{userInfo.accounts.black_money}$</td>
          </tr>

          <tr>
            <td colspan="2" class="font-bold text-center">{$_('punishment')}</td>
          </tr>
          {#if userInfo[selectedTab]}
            <tr>
              <td>{$_('admin')}</td>
              <td class="text-right">{userInfo[selectedTab].admin.name}</td>
            </tr>
            <tr>
              <td>{$_('admin_identifier')}</td>
              <td class="text-right">{userInfo[selectedTab].admin.identifier}</td>
            </tr>
            <tr>
              <td>{$_('start_date')}</td>
              <td class="text-right">{formatDate(userInfo[selectedTab].start)}</td>
            </tr>
            {#if selectedTab === 'ban'}
              <tr>
                <td>{$_('end_date')}</td>
                <td class="text-right">{formatDate(userInfo[selectedTab].endDate)}</td>
              </tr>
              <tr>
                <td>{$_('days')}</td>
                <td class="text-right">{userInfo[selectedTab].count}</td>
              </tr>
            {:else if selectedTab === 'jail'}
              <tr>
                <td>{$_('elapsed')}</td>
                <td class="text-right">{userInfo[selectedTab].count} minutes</td>
              </tr>
              <tr>
                <td>{$_('all_time')}</td>
                <td class="text-right">{userInfo[selectedTab].all} minutes</td>
              </tr>
            {/if}
          {/if}
        </tbody>
      </table>
    {/if}
  </div>
</div>

<input type="checkbox" id="settings-modal" class="modal-toggle" />
<div class="modal">
  <div class="modal-box bg-gray-800">
    <label for="settings-modal" class="btn btn-sm btn-circle absolute right-2 top-2">
      <i class="fa-solid fa-xmark" />
    </label>
    <h3 class="font-bold text-lg mb-3">{$_('settings')}</h3>

    <div class="w-full grid grid-cols-2 items-center">
      {$_('language')}
      <select on:change={({ target }) => locale.set(target.value)} class="select select-bordered select-sm w-full max-w-xs">
        {#each $locales as _locale}
          <option selected={$locale == _locale} value={_locale}>{_locale}</option>
        {/each}
      </select>
    </div>
  </div>
</div>

<style>
  main {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
  }
</style>
