<?php
/**
 * Recorded Classes Page — EduSys
 * Students & Teachers can view all recordings for classes they're part of.
 */
require_once __DIR__ . '/includes/header.php';
requireLogin();

$uid  = $_SESSION['user_id'];
$role = $_SESSION['role'];
$filter_class = (int)($_GET['class_id'] ?? 0);

if ($role === 'teacher') {
    $tid = $conn->query("SELECT id FROM teachers WHERE user_id=$uid")->fetch_assoc()['id'] ?? 0;
    $sql = "
        SELECT r.*, lc.title as class_title, lc.status as class_status,
               lc.start_time, lc.end_time, b.name as batch_name,
               u.name as teacher_name
        FROM recordings r
        JOIN live_classes lc ON r.class_id=lc.id
        LEFT JOIN batches b ON lc.batch_id=b.id
        LEFT JOIN teachers t ON lc.teacher_id=t.id
        LEFT JOIN users u ON t.user_id=u.id
        WHERE lc.teacher_id=$tid
        " . ($filter_class ? " AND r.class_id=$filter_class" : "") . "
        ORDER BY lc.id DESC, r.id ASC
    ";
} elseif ($role === 'student') {
    $sid = $conn->query("SELECT id FROM students WHERE user_id=$uid")->fetch_assoc()['id'] ?? 0;
    $sql = "
        SELECT r.*, lc.title as class_title, lc.status as class_status,
               lc.start_time, lc.end_time, b.name as batch_name,
               u.name as teacher_name
        FROM recordings r
        JOIN live_classes lc ON r.class_id=lc.id
        LEFT JOIN batches b ON lc.batch_id=b.id
        LEFT JOIN teachers t ON lc.teacher_id=t.id
        LEFT JOIN users u ON t.user_id=u.id
        WHERE (b.id IN (SELECT batch_id FROM batch_students WHERE student_id=$sid)
               OR lc.batch_id = 0
               OR lc.batch_id IS NULL)
        " . ($filter_class ? " AND r.class_id=$filter_class" : "") . "
        ORDER BY lc.id DESC, r.id ASC
    ";
} else {
    // Admin: all recordings
    $sql = "
        SELECT r.*, lc.title as class_title, lc.status as class_status,
               lc.start_time, lc.end_time, b.name as batch_name,
               u.name as teacher_name
        FROM recordings r
        JOIN live_classes lc ON r.class_id=lc.id
        LEFT JOIN batches b ON lc.batch_id=b.id
        LEFT JOIN teachers t ON lc.teacher_id=t.id
        LEFT JOIN users u ON t.user_id=u.id
        " . ($filter_class ? "WHERE r.class_id=$filter_class" : "") . "
        ORDER BY lc.id DESC, r.id ASC
    ";
}
$recordings = $conn->query($sql);

$classes = [];
if ($recordings && $recordings->num_rows > 0) {
    while ($row = $recordings->fetch_assoc()) {
        $cid = (int)$row['class_id'];
        if (!isset($classes[$cid])) {
            $classes[$cid] = [
                'class_id'     => $cid,
                'class_title'  => $row['class_title'] ?? 'Live Class',
                'class_status' => $row['class_status'] ?? 'ended',
                'start_time'   => $row['start_time'],
                'end_time'     => $row['end_time'],
                'batch_name'   => $row['batch_name'] ?? 'General',
                'teacher_name' => $row['teacher_name'] ?? 'Teacher',
                'created_at'   => $row['created_at'],
                'total_size'   => 0,
                'parts'        => []
            ];
        }
        $fsize = (int)($row['file_size'] ?? 0);
        $classes[$cid]['total_size'] += $fsize;
        $classes[$cid]['parts'][] = [
            'id'        => (int)$row['id'],
            'file_path' => $row['file_path'],
            'url'       => BASE_URL . $row['file_path'],
            'size'      => $fsize,
            'size_mb'   => $fsize > 0 ? (round($fsize / 1024 / 1024, 1) . ' MB') : '0 MB',
            'created_at'=> $row['created_at']
        ];
    }
}
?>
<div class="page-header">
    <div><h1>Recorded Classes</h1><p>Watch recorded live sessions from your classes</p></div>
</div>

<?php if (empty($classes)): ?>
<div class="table-card" style="text-align:center;padding:50px;">
    <i class="fa-solid fa-circle-play" style="font-size:3rem;color:var(--text-secondary);margin-bottom:16px;"></i>
    <h3 style="color:var(--text-secondary);">No recordings available yet</h3>
    <p style="color:var(--text-secondary);font-size:0.88rem;margin-top:8px;">Recordings will appear here after live classes are recorded and saved.</p>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px;">
    <?php foreach ($classes as $class_item):
        $parts_count = count($class_item['parts']);
        $total_size_mb = $class_item['total_size'] > 0 ? (round($class_item['total_size'] / 1024 / 1024, 1) . ' MB') : '';
        $duration_min = '';
        if ($class_item['start_time'] && $class_item['end_time']) {
            $diff = (strtotime($class_item['end_time']) - strtotime($class_item['start_time']));
            $duration_min = round($diff / 60) . ' min';
        }
        $parts_json = htmlspecialchars(json_encode($class_item['parts']), ENT_QUOTES, 'UTF-8');
        $first_part_url = $class_item['parts'][0]['url'] ?? '#';
    ?>
    <div style="background:var(--background);border-radius:18px;box-shadow:var(--neu-md);overflow:hidden;display:flex;flex-direction:column;border:1px solid rgba(100,100,100,0.1);">
        <!-- Thumbnail -->
        <div style="background:linear-gradient(135deg,#1a1d2e,#2d3461);padding:28px 20px;display:flex;align-items:center;justify-content:center;position:relative;">
            <i class="fa-solid fa-circle-play" style="font-size:2.8rem;color:rgba(255,255,255,.3);"></i>
            <span style="position:absolute;top:10px;right:10px;background:rgba(239,68,68,.9);color:#fff;border-radius:10px;padding:3px 8px;font-size:0.68rem;font-weight:700;display:flex;align-items:center;gap:4px;">
                <i class="fa-solid fa-circle" style="font-size:0.45rem;"></i> REC
            </span>
            <?php if ($parts_count > 1): ?>
            <span style="position:absolute;top:10px;left:10px;background:rgba(99,102,241,0.9);color:#fff;border-radius:10px;padding:3px 8px;font-size:0.68rem;font-weight:700;">
                <i class="fa-solid fa-layer-group"></i> <?= $parts_count ?> Parts
            </span>
            <?php endif; ?>
            <?php if ($duration_min): ?>
            <span style="position:absolute;bottom:10px;right:10px;background:rgba(0,0,0,.65);color:#fff;border-radius:8px;padding:3px 8px;font-size:0.68rem;">
                <?= $duration_min ?>
            </span>
            <?php endif; ?>
        </div>

        <!-- Info -->
        <div style="padding:18px;flex:1;display:flex;flex-direction:column;">
            <h4 style="margin:0 0 8px;font-size:0.96rem;"><?= htmlspecialchars($class_item['class_title']) ?></h4>
            <div style="font-size:0.78rem;color:var(--text-secondary);display:flex;flex-direction:column;gap:5px;flex:1;">
                <span><i class="fa-solid fa-layer-group" style="width:14px;"></i> <?= htmlspecialchars($class_item['batch_name']) ?></span>
                <span><i class="fa-solid fa-chalkboard-user" style="width:14px;"></i> <?= htmlspecialchars($class_item['teacher_name']) ?></span>
                <span><i class="fa-solid fa-calendar" style="width:14px;"></i> <?= date('M d, Y', strtotime($class_item['created_at'])) ?></span>
                <?php if ($total_size_mb): ?>
                <span><i class="fa-solid fa-file-video" style="width:14px;"></i> Total: <?= $total_size_mb ?><?php if ($parts_count > 1): ?> (<?= $parts_count ?> parts, &lt; 8MB each)<?php endif; ?></span>
                <?php endif; ?>
            </div>

            <!-- Parts pills if multiple parts -->
            <?php if ($parts_count > 1): ?>
            <div style="margin-top:12px;padding:8px;background:rgba(100,100,100,0.06);border-radius:10px;display:flex;flex-wrap:wrap;gap:6px;align-items:center;">
                <span style="font-size:0.7rem;font-weight:700;color:var(--text-secondary);text-transform:uppercase;">Parts:</span>
                <?php foreach ($class_item['parts'] as $pidx => $part): ?>
                <button onclick="playRecording(<?= htmlspecialchars(json_encode($class_item['class_title'])) ?>, '<?= $parts_json ?>', <?= $pidx ?>)"
                        style="padding:3px 8px;border-radius:6px;background:var(--surface);border:1px solid rgba(100,100,100,0.18);font-size:0.72rem;font-weight:600;cursor:pointer;color:var(--text);"
                        title="Play Part <?= $pidx + 1 ?> (<?= $part['size_mb'] ?>)">
                    Part <?= $pidx + 1 ?>
                </button>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>

            <!-- Action buttons -->
            <div style="margin-top:14px;display:flex;gap:8px;flex-wrap:wrap;">
                <button onclick="playRecording(<?= htmlspecialchars(json_encode($class_item['class_title'])) ?>, '<?= $parts_json ?>', 0)"
                        class="btn btn-primary btn-sm"
                        style="flex:1;text-align:center;display:flex;align-items:center;justify-content:center;gap:6px;">
                    <i class="fa-solid fa-play"></i> <?= $parts_count > 1 ? 'Watch All (Auto-Play)' : 'Watch' ?>
                </button>
                <a href="<?= $first_part_url ?>"
                   download
                   class="btn btn-outline btn-sm"
                   title="Download <?= $parts_count > 1 ? 'Part 1' : 'Recording' ?>">
                    <i class="fa-solid fa-download"></i>
                </a>
                <a href="<?= BASE_URL ?>live_class_room.php?class_id=<?= $class_item['class_id'] ?>&review=1"
                   class="btn btn-outline btn-sm"
                   title="View Classroom History">
                    <i class="fa-solid fa-comments"></i>
                </a>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<!-- Modern Video Player Modal with Seamless Multi-Part Playlist Support -->
<div id="videoPlayerModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.85);z-index:99999;backdrop-filter:blur(8px);align-items:center;justify-content:center;padding:16px;">
    <div style="background:var(--surface,#1a1d2e);width:100%;max-width:940px;border-radius:18px;overflow:hidden;box-shadow:0 24px 48px rgba(0,0,0,0.6);border:1px solid rgba(255,255,255,0.12);display:flex;flex-direction:column;">
        <div style="padding:14px 20px;display:flex;align-items:center;justify-content:space-between;background:rgba(0,0,0,0.35);border-bottom:1px solid rgba(255,255,255,0.08);">
            <div>
                <h3 id="playerModalTitle" style="margin:0;font-size:1.05rem;color:#fff;">Class Recording</h3>
                <span id="playerModalSubtitle" style="font-size:0.75rem;color:var(--text-sec,#94a3b8);">Playing Part 1</span>
            </div>
            <button onclick="closePlayerModal()" style="background:none;border:none;color:#fff;font-size:1.6rem;cursor:pointer;padding:0 8px;line-height:1;border-radius:6px;">&times;</button>
        </div>
        <div style="background:#000;position:relative;display:flex;align-items:center;justify-content:center;">
            <video id="modalVideo" controls autoplay playsinline style="width:100%;max-height:65vh;background:#000;"></video>
        </div>
        <div id="playerPartsContainer" style="padding:12px 20px;display:flex;align-items:center;gap:8px;flex-wrap:wrap;background:rgba(0,0,0,0.25);border-top:1px solid rgba(255,255,255,0.06);">
            <!-- Playlist parts buttons -->
        </div>
    </div>
</div>

<script>
let currentPlaylist = [];
let currentPlaylistIndex = 0;
const modalEl = document.getElementById('videoPlayerModal');
const videoEl = document.getElementById('modalVideo');

function playRecording(classTitle, partsJson, startIndex = 0) {
    let parts = [];
    try {
        parts = typeof partsJson === 'string' ? JSON.parse(partsJson) : partsJson;
    } catch(e) {
        console.error('Invalid parts JSON:', e);
        return;
    }

    if (!parts || parts.length === 0) return;

    currentPlaylist = parts;
    currentPlaylistIndex = startIndex >= 0 && startIndex < parts.length ? startIndex : 0;
    document.getElementById('playerModalTitle').textContent = classTitle || 'Class Recording';

    renderPlayerParts();
    loadCurrentPart();
    modalEl.style.display = 'flex';
}

function loadCurrentPart() {
    if (!currentPlaylist[currentPlaylistIndex]) return;
    const part = currentPlaylist[currentPlaylistIndex];
    document.getElementById('playerModalSubtitle').textContent = `Playing Part ${currentPlaylistIndex + 1} of ${currentPlaylist.length} (${part.size_mb || ''})`;
    videoEl.src = part.url;
    videoEl.play().catch(() => {});
    highlightActivePart();
}

videoEl.addEventListener('ended', () => {
    if (currentPlaylistIndex < currentPlaylist.length - 1) {
        currentPlaylistIndex++;
        loadCurrentPart();
    }
});

function selectPart(idx) {
    currentPlaylistIndex = idx;
    loadCurrentPart();
}

function highlightActivePart() {
    const btns = document.querySelectorAll('.part-btn-item');
    btns.forEach((b, idx) => {
        if (idx === currentPlaylistIndex) {
            b.style.background = '#4f46e5';
            b.style.color = '#fff';
            b.style.borderColor = '#4f46e5';
        } else {
            b.style.background = 'rgba(255,255,255,0.06)';
            b.style.color = 'var(--text,#fff)';
            b.style.borderColor = 'rgba(255,255,255,0.15)';
        }
    });
}

function renderPlayerParts() {
    const container = document.getElementById('playerPartsContainer');
    if (currentPlaylist.length <= 1) {
        container.style.display = 'none';
        return;
    }
    container.style.display = 'flex';
    container.innerHTML = '<span style="font-size:0.75rem;color:var(--text-sec,#94a3b8);font-weight:700;margin-right:6px;"><i class="fa-solid fa-list-ol"></i> PARTS:</span>' + 
        currentPlaylist.map((p, idx) => `
            <button class="part-btn-item" onclick="selectPart(${idx})" style="padding:6px 14px;border-radius:20px;border:1px solid rgba(255,255,255,0.15);cursor:pointer;font-size:0.78rem;font-weight:600;display:flex;align-items:center;gap:6px;transition:background 0.2s;">
                <i class="fa-solid fa-play" style="font-size:0.6rem;"></i> Part ${idx + 1} (${p.size_mb})
            </button>
        `).join('');
}

function closePlayerModal() {
    videoEl.pause();
    videoEl.src = '';
    modalEl.style.display = 'none';
}

// Close modal when clicking backdrop
modalEl.addEventListener('click', (e) => {
    if (e.target === modalEl) closePlayerModal();
});
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
