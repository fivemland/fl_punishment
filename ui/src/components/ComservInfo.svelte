<script>
  import { _ } from 'svelte-i18n';

  import InfoBar from './InfoBar.svelte';

  let comserv = false;

  window.addEventListener('message', ({ data }) => {
    if (data.comserv !== undefined) comserv = data.comserv;
  });

  $: formatedDate = comserv ? new Date((comserv.start || 0) * 1000).toLocaleString('en-GB') : false;
</script>

{#if comserv && typeof comserv === 'object'}
  <main id="infopanel" class="bg-gray-700 p-2 rounded-xl select-none">
    <div class="text-center font-bold mb-2">{$_('comserv')}</div>

    <InfoBar title={$_('tasks_left')} value={`${comserv.count || 'Unknown'}/${comserv.all || 'Unknown'}`} />
    <InfoBar title={$_('reason')} value={comserv.reason || 'Unknown'} />
    <InfoBar title={$_('admin')} value={comserv.admin ? comserv.admin.name : 'Unknown'} />
    <InfoBar title={$_('start_date')} value={formatedDate || 'Unknown'} />
  </main>
{/if}
