<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Mahasiswa;

class MahasiswaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Mahasiswa::create([
            'nim' => '244107020154',
            'nama' => 'Hafiz Rizqi Hernanda',
            'prodi' => 'D4 Teknik Informatika',
            'email' => 'hafiz@example.com',
        ]);
        Mahasiswa::create([
            'nim' => '2341720002',
            'nama' => 'Bunga Lestari',
            'prodi' => 'D4 Sistem Informasi Bisnis',
            'email' => 'bunga@example.com',
        ]);
    }
}
