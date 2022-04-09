<script>
  import Loading from './Loading.svelte';

  const buttons = [
    { name: 'comserv', label: 'Community Service' },
    { name: 'jail', label: 'Jail' },
    { name: 'ban', label: 'Ban' },
  ];
  let visible = false;
  let selectedTab = 'comserv';

  let users = [];
  let search = '';

  $: filteredUsers = users.filter((user) => user.name.toLowerCase().includes(search.toLowerCase()));

  $: activeTab = buttons.find((button) => button.name === selectedTab);

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
    <div class="flex justify-between items-center text-xl">
      {activeTab.label}s

      <button on:click={close} class="text-error">
        <i class="fa-solid fa-xmark" />
      </button>
    </div>
    <div class="flex justify-between">
      <div class="flex">
        {#each buttons as button}
          <button on:click={() => selectTab(button.name)} class="btn btn-sm btn-info mx-1">
            {button.label}
          </button>
        {/each}
      </div>
      <div class="mb-2">
        <input
          bind:value={search}
          disabled={users.length <= 0 || filteredUsers.length <= 0}
          type="text"
          placeholder="Search"
          class="input input-bordered input-sm w-full"
        />
      </div>
    </div>

    <div class="max-h-96 overflow-y-auto">
      {#if search.length > 0 && filteredUsers.length <= 0}
        <div class="text-center text-warning text-lg mt-4">
          Search result:
          <br />
          Users not found!
        </div>
      {/if}

      {#if users.length <= 0 || filteredUsers.length <= 0}
        <div class="text-center text-warning text-lg mt-4">Users not found!</div>
      {:else}
        {#each filteredUsers as user}
          {#if user}
            <div class="grid grid-flow-col gap-2 items-center bg-slate-800 p-2 rounded-md border-b border-gray-900">
              <div class="w-40">{user.name || 'Ismeretlen'}</div>
              <div class="w-60 text-center">
                <div class="tooltip tooltip-left" data-tip="Reason">
                  {user[selectedTab].reason || 'Unknown'}
                </div>
              </div>
              <div>
                <div class="tooltip tooltip-right" data-tip="Count">
                  {#if selectedTab === 'ban'}
                    {parseInt(user[selectedTab].count || 0) === 0 ? 'Infinity' : user[selectedTab].count + ' days'}
                  {:else}
                    {user[selectedTab].count || 0}/{user[selectedTab].all || 0}
                  {/if}
                </div>
              </div>
              <div class="ml-auto">
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
    <label on:click={(userInfo = false)} for="info-modal" class="btn btn-sm btn-circle absolute right-2 top-2">
      <i class="fa-solid fa-xmark" />
    </label>
    <h3 class="font-bold text-lg">User Informations</h3>

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
            <td colspan="2" class="font-bold text-center"> User Informations </td>
          </tr>

          <tr>
            <td>Identifier</td>
            <td class="text-right">{userInfo.identifier || 'Unknown'}</td>
          </tr>
          <tr>
            <td>Character Name</td>
            <td class="text-right">{userInfo.firstname || 'Unknown'} {userInfo.lastname || 'Unknown'}</td>
          </tr>
          <tr>
            <td>Job</td>
            <td class="text-right">{userInfo.job || 'Unknown'}</td>
          </tr>
          <tr>
            <td>Money</td>
            <td class="text-right">{userInfo.accounts.money}$</td>
          </tr>
          <tr>
            <td>Bank Money</td>
            <td class="text-right">{userInfo.accounts.bank}$</td>
          </tr>
          <tr>
            <td>Dirt Money</td>
            <td class="text-right">{userInfo.accounts.black_money}$</td>
          </tr>

          <tr>
            <td colspan="2" class="font-bold text-center"> Punishment </td>
          </tr>
          {#if userInfo[selectedTab]}
            <tr>
              <td>Admin</td>
              <td class="text-right">{userInfo[selectedTab].admin.name}</td>
            </tr>
            <tr>
              <td>Admin Identifier</td>
              <td class="text-right">{userInfo[selectedTab].admin.identifier}</td>
            </tr>
            <tr>
              <td>Start Date</td>
              <td class="text-right">{formatDate(userInfo[selectedTab].start)}</td>
            </tr>
            {#if selectedTab == 'ban'}
              <tr>
                <td>End Date</td>
                <td class="text-right">{formatDate(userInfo[selectedTab].endDate)}</td>
              </tr>
              <tr>
                <td>Days</td>
                <td class="text-right">{userInfo[selectedTab].count}</td>
              </tr>
            {/if}
          {/if}
        </tbody>
      </table>
    {/if}
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
