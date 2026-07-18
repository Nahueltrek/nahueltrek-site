import { supabase } from "./supabaseClient";

/**
 * Fetch every row of a table, ordered by a column.
 */
export async function fetchTable(table, orderBy) {
  const { data, error } = await supabase.from(table).select("*").order(orderBy);
  if (error) throw error;
  return data;
}

/**
 * Sync a full in-memory list back to a Supabase table: upserts every row
 * in `newList` and deletes any row that was in `oldList` but is gone from
 * `newList`. This lets the rest of the app keep using the simple
 * "replace the whole list" pattern instead of hand-writing insert/update/
 * delete calls in every admin screen.
 */
export async function syncTable(table, oldList, newList) {
  const newIds = new Set(newList.map((x) => x.id));
  const removedIds = oldList.filter((x) => !newIds.has(x.id)).map((x) => x.id);

  if (newList.length > 0) {
    const { error: upsertError } = await supabase.from(table).upsert(newList);
    if (upsertError) throw upsertError;
  }
  if (removedIds.length > 0) {
    const { error: deleteError } = await supabase.from(table).delete().in("id", removedIds);
    if (deleteError) throw deleteError;
  }
}
