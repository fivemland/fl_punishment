<script>
  let comserv = false;

  window.addEventListener('message', ({ data }) => {
    if (data.comserv !== undefined) comserv = data.comserv;
  });

  $: formatedDate = comserv ? new Date((comserv.start || 0) * 1000).toLocaleString('en-GB') : false;
</script>

{#if comserv && typeof comserv === 'object'}
  <main class="bg-gray-700 p-2 rounded-xl">
    <div class="text-center font-bold mb-2">Community Service</div>
    <table class="table table-compact">
      <tbody class="text-center">
        <tr>
          <td>Tasks Left</td>
          <td>{comserv.count || 'Unknown'}</td>
        </tr>
        <tr>
          <td>Reason</td>
          <p class="text-sm p-1 bg-base-100 border-b border-base-200 max-w-xs break-words">
            {comserv.reason || 'Unknown'}
          </p>
        </tr>
        <tr>
          <td>Admin</td>
          <td>{comserv.admin ? comserv.admin.name : 'Unknown'}</td>
        </tr>
        <tr>
          <td>Start Date</td>
          <td>{formatedDate || 'Unknown'}</td>
        </tr>
      </tbody>
    </table>
  </main>
{/if}

<style>
  main {
    position: absolute;
    left: 50%;
    bottom: 1rem;
    transform: translateX(-50%);
  }
</style>
